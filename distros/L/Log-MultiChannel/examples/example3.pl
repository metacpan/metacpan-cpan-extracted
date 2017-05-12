#!/usr/bin/perl
# Example 3: Two channels to two log files, with one channel duplicated in both
use strict;
use warnings;
use Log::MultiChannel qw(Log);
my $logfile1='example3-both.log';
my $logfile2='example3-error.log';
Log::MultiChannel::startLogging($logfile1);
Log::MultiChannel::startLogging($logfile2);

Log::MultiChannel::mapChannel('INF',$logfile1); # Put INF messages in myLogFile1.log
Log::MultiChannel::mapChannel('ERR',$logfile1,$logfile2); # Put ERR messages in logfile1 and logfile2

Log('INF',"This is an info message for $logfile1");
Log('ERR',"This is an Error message for $logfile1 & $logfile2");

Log::MultiChannel::closeLogs(); # This will close ALL log files that are open
exit;
