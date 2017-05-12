#!/bin/bash

PWD=`pwd`
TESTDIR='/tmp/hpcrunner-sqlite'

rm -rf $TESTDIR
mkdir -p $TESTDIR
cp t/test001/script/test001.1.sh $TESTDIR
cp t/test001/.hpcrunner.yml $TESTDIR

cd $TESTDIR
perl  `which hpcrunner.pl` submit_jobs --infile test001.1.sh --use_batches --hpc_plugins Dummy --hpc_plugins_opts cleandb=1 --project 'MYPROJECT'
find hpc-runner/MYPROJECT/scratch/ -name "*.sh" | xargs -I {} bash {}

cd $TESTDIR
perl  `which hpcrunner.pl` submit_jobs --infile test001.1.sh --use_batches --hpc_plugins Dummy  --project 'MY_NEW_PROJECT'
find hpc-runner/MY_NEW_PROJECT/scratch/ -name "*.sh" | xargs -I {} bash {}

cd $PWD
