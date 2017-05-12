#!/bin/sh
#this is just a little sample script of how I run the program.

#my crontab is like this which runs it at 0242 in the morning..
#42 02 * * *	/..directories./LinkController/testing-links/run-daily-test.sh


#assumes the use of a gnu style date command which can print out full dates.
. $HOME/.shrc
LOGDIR=$HOME/log
cd $HOME/development/mom-virtual/MOMspider/link-test
perl daily-test-link.pl -v > $LOGDIR/runlog-`/bin/date +%Y-%m-%d`.log 2>&1 

