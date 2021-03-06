
srcdir = "C:\\Users\\zetan\\workspace\\MotionDL\\code\\r\\discovery\\"
source(paste(srcdir, "util.R", sep=''))
source(paste(srcdir, "self-training_co-training.R", sep=''))

dataset = "UBICOMP"
if(dataset == "PLCouple1"){
  base="D:\\lessons\\motion recognition\\dataset\\PLCouple1\\sensor\\";
  setwd(base);
}
if(dataset== "UBICOMP"){
  base = "D:\\lessons\\motion recognition\\dataset\\dataset_huynh_ubicomp08"
  setwd(base);
}

if(dataset == "PAMAP"){
  base = "D:\\lessons\\motion recognition\\dataset\\PAMAP2_Dataset\\Protocol";
  setwd(base);
}


framesInDoc = 2 * 30 #ubicomp
#framesInDoc = 2*10 #pamap

#================ prepare data ========================

feature = "NEW_FEATURE"

if(feature == "OLD_FEATURE"){
  load("sub102_iron_unknown_walking_sitting_lying.R")  #classifiers
  
  day = 2
  filesnames =  paste("data\\day", day, "-data.txt", sep='');
  labelfiles = paste("label\\day", day, "-activities.txt", sep='')
  label = read.ubilabel(labelfiles, "activities.txt");
  if(dataset == "PLCouple1"){
    testdata_date = "2006-09-14"
    testdata_dir = "2006-09-14\\acc_data_fps2_matched"
    
    rawData = read.files(paste(testdata_dir, list.files(testdata_dir), sep="\\"))
    
    data = rawData[,5:20]
    label = rawData[, 21]
    featureCnt = 16;
    features = c('hip1_x', 'hip1_y', 'hip1_z', 'hip2_x', 'hip2_y', 'hip2_z', 'wrist_x','wrist_y','wrist_z',
                 'thigh_x','thigh_y','thigh_z','hip1_var', 'hip2_var', 'wrist_var', 'thigh_var');
  }
  
  if(dataset == "UBICOMP"){
    
    rawData = read.files(filesnames)
    data = rawData[,1:12]
    featureCnt = 12; 
    #read label  
    
    features = c("pocket_x", "pocket_y", "pocket_z", "pocket_var_x", "pocket_var_y", "pocket_var_z",
                 "wrist_x", "wrist_y", "wrist_z", "wrist_var_x", "wrist_var_y", "wrist_var_z");
    # docCnt = as.integer(length(label) / framesInDoc)
    # label = label[1:(framesInDoc*docCnt)]
    
    
    for(i in c(4:6,10:12)){data[,i] = vector.removenoise(data[, i], 0.02);}
  }
  if(dataset == "PAMAP"){
    filename = "subject102.dat"
    data = read.downsample.pamap(filename, 2);
    featureCnt = 18;
    label = read.downsample.label.pamap(filename, 2);
    docCnt = as.integer(length(label) / framesInDoc);
    label = label[1:(framesInDoc*docCnt)];
  }
  
  
  docCnt = as.integer(length(label) / framesInDoc)
  
  extend = "fft_energy_entropy";
  if(dataset == "UBICOMP"){
    raw_sensor_dim = c(1, 2, 3,7, 8, 9);
    if(extend == "fft_coe"){
      fftnum = 5;
      extendedFeatureCnt = featureCnt + length(raw_sensor_dim) * fftnum * 2;
      features = c(features, paste("fft", c(1:(length(raw_sensor_dim) * fftnum * 2)), sep='_'))
    }
    if(extend == "fft_energy_entropy"){
      N = length(raw_sensor_dim);
      extendedFeatureCnt = featureCnt + N * 2;
      features = c(features, paste("energy",c(1:N), sep='_'), paste("entropy", c(1:N), sep='_'));
    }
  }
  
  if(dataset == "PAMAP"){
    features = c('hip_x', 'hip_y', 'hip_z', 'hand_x', 'hand_y', 'hand_z', 'ankle_x', 'ankle_y', 'ankle_z',
                 'hip_var_x', 'hip_var_y', 'hip_var_z', 'hand_var_x', 'hand_var_y', 'hand_var_z',
                 'ankle_var_x', 'ankle_var_y', 'ankle_var_z');
    raw_sensor_dim = c(1:9);
    N = length(raw_sensor_dim);
    extendedFeatureCnt = featureCnt + N * 2;
    features = c(features, paste("energy",c(1:N), sep='_'), paste("entropy", c(1:N), sep='_'));
  }
  
  doc_data_m = matrix(0,nrow = docCnt, ncol = extendedFeatureCnt)
  for(row in 1:docCnt){
    for(col in 1:length(data[1,])){
      frameRows = ((row-1)*framesInDoc + 1) : (row * framesInDoc)
      doc_data_m[row, col] = mean(data[frameRows, col])
    }
    if(extend == "fft_coe"){
      doc_data_m[row, (featureCnt+1):extendedFeatureCnt] = data.fft(data.frame(data[frameRows, raw_sensor_dim]), fftnum);
    }
    if(extend == "fft_energy_entropy"){
      doc_data_m[row, (featureCnt+1):extendedFeatureCnt] = data.fft_energy_entropy(data.frame(data[frameRows, raw_sensor_dim]));
    }
  }
  
  
  doc_data_m =  dataframe.normalize(doc_data_m);
}

if(feature == "NEW_FEATURE_UBI"){
  load("classifiers_newfeature\\day2_meeting_desk_unknown_walk_phone.RData")# load classifiers
  load("classifiers_newfeature\\day2_doc_data_clu.RData") # load doc_data_clu
  doc_data_m = doc_data_clu
  
  label = read.ubilabel("label\\day2-activities.txt", "activities.txt"); #load ground-truth labels
}

if(feature == "NEW_FEATURE_PAMAP"){
  setwd("D:\\lessons\\motion recognition\\dataset\\PAMAP2_Dataset\\experiment\\")
  framesInDoc = 2*10
  load("classifiers_new_feature\\109_fold_computer_house_soccer.RData")
  data = read.table("data_subject109_all.txt") #load data
  label = c(read.table("label_subject109_all.txt")[,1]) #load ground-truth label
  docCnt = as.integer(length(label) / framesInDoc)
  
  doc_labels = 1:docCnt
  for(docIndex in 1:docCnt){
    doc_labels[docIndex] = voteMajor(label[((docIndex-1)*framesInDoc+1):(docIndex*framesInDoc)])
  }
  
  doc_data_clu_m = matrix(0, nrow = length(doc_labels), ncol=9)
  for(i in 1:length(doc_labels)){
    start = (i-1) * framesInDoc + 1
    end = i * framesInDoc
    hip = data[start:end, 1:3]
    hand = data[start:end, 4:6]
    ankle = data[start:end, 7:9]
    doc_data_clu_m[i, ] = get_train_feature.pamap(hip, hand, ankle);
  }
  doc_data_clu = data.frame(doc_data_clu_m)
  doc_data_clu = dataframe.normalize(doc_data_clu);
  
  doc_data_m = doc_data_clu  
}
#===================== generate doc label =============================
docCnt = length(doc_data_m[,1])
doc_labels = 1:docCnt
for(docIndex in 1:docCnt){
  doc_labels[docIndex] = voteMajor(label[((docIndex-1)*framesInDoc+1):(docIndex*framesInDoc)])
}
doc_label_set = as.integer(names(table(doc_labels)))

test_classifier_indexes = c(1,2,4,5)
ground_truth_activities = c(34, 14,20,18)

  # remove unlabeled data
  unlabelled_index = which(doc_labels == 0);
  doc_labels = doc_labels[-unlabelled_index];
  doc_data_m = doc_data_m[-unlabelled_index,];
  docCnt = length(doc_labels)   # remove unknowns

  test_x = data.frame(doc_data_m)
  colnames(test_x) = paste("f_", c(1:length(test_x[1,])), sep='');
  
  
  #================= visualize ground truth =============================
  colors = c('gray','orange', 'red', 'blue',  'green',  'brown', 'cornflowerblue',
             'pink', 'green4', 'lightcoral', 'mediumslateblue', 'navy','saddlebrown','navajowhite',
              'gray20', 'darkgoldenrod3', 'dodgerblue', 'gold4', 'deeppink4')
  
  viz_ground_truth(dataset, doc_labels);
  
  #==================== classify data with models ==================================
  classify_results = c();
  predscore_results = c();
  
  
  coverage = rep("x", length(test_classifier_indexes));
  sensitivity=rep("x", length(test_classifier_indexes));
  specify=rep("x", length(test_classifier_indexes));
  precision=rep("x", length(test_classifier_indexes));
  accuracy=rep("x", length(test_classifier_indexes));
  
  build_percent_str = function(numerator, denumerator){
    percent = format(round(numerator /denumerator, 2), nsmall = 2)
    return(ifelse(denumerator==0, "", paste(percent, " (", toString(numerator), "/", toString(denumerator), ")", sep='')));
  }
  
  
  for(i in 1:length(test_classifier_indexes)){
    classifier_index = test_classifier_indexes[i];
    activity = ground_truth_activities[i]
    ground_truth_act = ground_truth_activities[i]
    
    pred_score = c(svm.predict(classifiers[[classifier_index]], test_x))
    pred_class = ifelse(pred_score>0, T, F)
    pred_class = smooth_classify_tag(pred_class);
    classify_results = rbind(classify_results, pred_class);
    predscore_results = rbind(predscore_results, pred_score);
    
    ground_pos = which(doc_labels == activity)  #true_positive + false_negative
    ground_neg = which(doc_labels != activity)  #true_negative + false_positive
    
    test_y_pos = which(pred_class == T)
    test_y_neg = which(pred_class == F)
    
    pos = length(ground_pos)  
    neg = length(ground_neg)   
    t_pos = length(intersect(ground_pos, test_y_pos))
    t_neg = length(intersect(ground_neg, test_y_neg))
    f_pos = length(intersect(ground_neg, test_y_pos))
    
    
    #sensitivity = t_pos / pos;
    #specify = t_neg / neg
    #precision = t_pos / (t_pos + f_pos)
    #accuracy = (t_pos + t_neg) / length(pred_class)
    coverage[i] = build_percent_str(pos, pos+neg);
    
    sensitivity[i] = build_percent_str(t_pos, pos);
    specify[i] = build_percent_str(t_neg, neg)
    precision[i] = build_percent_str(t_pos, t_pos + f_pos);
    accuracy[i] = build_percent_str(t_pos + t_neg, pos + neg) 
    
    for(doc in 1:docCnt){
      points(x=doc, y=1 - 0.15*i, col=ifelse(pred_class[doc]==T, 'green', 'red'), pch=16);
    }
  }
  results = data.frame(coverage, sensitivity, specify,  accuracy)
  print(results);



  
  # computing and visualizing clustering result
  raw_classes = classifyByMax(classify_results, predscore_results);
  smoothed_classes = smoothResults(raw_classes, 15);
  #writeDiary(smoothed_classes, 15);
  
  viz_ground_truth(dataset, doc_labels);
 
  legend(length(doc_labels) * 1.03,1.5,inset=c(0,0),c("pattern-1","pattern-2","pattern-3"),pch=c(2, 18, 4),col="black", );
  
  pches = c(2, 18, 1, 16)
  class_colors = c('green', 'navy', 'brown', 'orange', 'pink');
   for(doc in 1:docCnt){
     if(raw_classes[doc] > 0){
       points(x=doc, y=1 , col=class_colors[raw_classes[doc]], pch=16); 
     }
     if(smoothed_classes[doc] > 0){
       points(x=doc, y=1.2, col=class_colors[smoothed_classes[doc]], pch=16);
     }
   }
  
 


classifyByMax = function(classify_results, predscore_results){
  results = rep(-1, docCnt);
  for(i in 1:docCnt){
    class_res = classify_results[, i];
    is_known = ifelse(length(class_res[class_res==T]) > 0, T, F);
    if(is_known == T){
      score = predscore_results[, i];
      results[i] = which(score == max(score));
    }
  }
  return(results);
}

smoothResults = function(classList, windowSize){
  smoothed = rep(-1, length(classList));
  len = length(classList);
  for(i in (windowSize/2) : (len - windowSize/2 - 1)){
    window = classList[(i - windowSize/2+1) : (i+windowSize/2)]
    major = as.integer(names(sort(table(window),decreasing=TRUE))[1])
    if(length(window[window==major]) >= windowSize*0.5){
      smoothed[i] = major;
    }
  }
  return(smoothed);
}

writeDiary = function(classList, minLength){
  activity_name = c("sitting desk working", "discussing at whiteboard", "picking up mensa food", "walking", "fanning barbecue");
  doc_time = getDocTime()
  findActivity = F;
  start = 0;
  end = 0;
  for(i in 1:docCnt){
    if(findActivity == F){
      if(classList[i] > 0){
        start = i;
        findActivity = T;
      }
    }else{
      if(classList[i] != classList[start]){
        end = i;
        findActivity = F;
        if(end - start >= minLength){
          print(paste(doc_time[start], "~", doc_time[end], ",", activity_name[classList[start]]));
        } 
      }
    }
  } 
}

getDocTime = function(){
  doc_num_time = rawData[c(1:docCnt) * framesInDoc, 14];
  doc_time = as.POSIXct(doc_num_time - 8 * 60*60, origin = "1970-01-01");
  return(doc_time);
}

