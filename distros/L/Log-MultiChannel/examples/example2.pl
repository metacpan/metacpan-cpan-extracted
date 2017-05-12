#!/usr/bin/perl
# Example 2: Two channels to two log files
use strict;
use warnings;
use Log::MultiChannel qw(Log);
my $logfile1='example2-inf.log';
my $logfile2='example2-err.log';

Log::MultiChannel::startLogging($logfile1);
Log::MultiChannel::startLogging($logfile2);

Log::MultiChannel::mapChannel('INF',$logfile1); # Put INF messages in myLogFile1.log
Log::MultiChannel::mapChannel('ERR',$logfile2); # Put ERR messages in myLogFile2.log

Log('INF',"This is an Error message for $logfile1");
Log('ERR',"This is an info message for $logfile2");

Log::MultiChannel::closeLogs(); # This will close ALL log files that are open
exit;
