#!/usr/bin/env bash

set -ex

###UPDATING TESTS

exit 0


############ Install bats
cd /tmp
wget https://github.com/sstephenson/bats/archive/v0.4.0.tar.gz
tar -xvf v0.4.0.tar.gz
cd bats-0.4.0
./install.sh /usr/local

############ Begin testing

cd /hpc-runner-command
BASE_DIR="/hpc-runner-command/ci-tests/slurm"


#TODO Update everything to use BATS

############ Begin slurm testing
/usr/sbin/munged
/usr/sbin/slurmctld
/usr/sbin/slurmd start

bats ci-tests/slurm/run-slurm-tests.bats

### This has all been moved to the bats testing protocol
#cd /hpc-runner-command
#milla install

#Additionally, we need the HPC-Runner-Command-Plugin-Logger-Sqlite libraries to watch our submission

#if [[ -z "${HPC_SQLITE_BRANCH}" ]] ; then
    #echo "NO HPC-Runner-Command-Plugin-Logger-Sqlite branch specified. Installing from master."
    #cpanm --quiet --notest git://github.com/jerowe/HPC-Runner-Command-Plugin-Logger-Sqlite.git@${HPC_SQLITE_BRANCH}
#else
    #echo "Installing HPC-Runner-Command-Plugin-Logger-Sqlite from develop"
    #cpanm --quiet --notest git://github.com/jerowe/HPC-Runner-Command-Plugin-Logger-Sqlite.git@${HPC_SQLITE_BRANCH}
#fi


#PWD=`pwd`

############ Simple test
#TESTDIR='/hpcunner-slurm-001-test-simple'
#
#rm -rf $TESTDIR
#mkdir -p $TESTDIR
#cp ${BASE_DIR}/test001-simple.submit $TESTDIR
#
#cd $TESTDIR
#hpcrunner.pl submit_jobs --infile test001-simple.submit --hpc_plugins Slurm,Logger::Sqlite --hpc_plugins_opts cleandb=1
#time hpcrunner.pl watch_db --plugins Logger::Sqlite --plugins_opts submission_id=1
#
#cd $PWD
#rm -rf $TESTDIR

############ Linear Deps test

#TESTDIR='/hpcunner-slurm-002-test-lineardeps'

#rm -rf $TESTDIR
#mkdir -p $TESTDIR
#cp ${BASE_DIR}/test002-lineardeps.submit $TESTDIR

#cd $TESTDIR
#hpcrunner.pl submit_jobs --infile test002-lineardeps.submit --hpc_plugins Slurm,Logger::Sqlite --hpc_plugins_opts cleandb=1
#time hpcrunner.pl watch_db   --plugins Logger::Sqlite --plugins_opts submission_id=1

#cd $PWD
#rm -rf $TESTDIR

############ Linear Deps test

#TESTDIR='/hpcunner-slurm-003-test-non_lineardeps'

#rm -rf $TESTDIR
#mkdir -p $TESTDIR
#cp ${BASE_DIR}/test003-non_lineardeps.submit $TESTDIR

#cd $TESTDIR
#hpcrunner.pl submit_jobs --infile `pwd`/test003-non_lineardeps.submit --hpc_plugins Slurm,Logger::Sqlite --hpc_plugins_opts cleandb=1
#time hpcrunner.pl watch_db  --plugins Logger::Sqlite --plugins_opts submission_id=1

#cd $PWD
#rm -rf $TESTDIR

############ End tests

echo "ALL PROCESSES EXITED SUCCESSFULLY"
