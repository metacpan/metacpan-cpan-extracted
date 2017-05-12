#!/bin/sh -x

#1) copy the input file to your hadoop dfs
#2) build the hadoop job, (using 0.20 file layout)

hadoop dfs -copyFromLocal input ./

hadoop                     \
    jar /usr/lib/hadoop/contrib/streaming/hadoop-0.20.1+152-streaming.jar \
    -input   input          \
    -output  myoutput       \
    -mapper  map.pl         \
    -reducer reduce.pl      \
    -file    map.pl         \
    -file    reduce.pl 
