#!/usr/bin/perl
# Example 5: Like example 3, Two channels to two log files, with one channel duplicated in both
# Then do a total of messages sent to  all log channels
use strict;
use warnings;
use Log::MultiChannel qw(Log);
my $logfile1='example5-both.log';
my $logfile2='example5-error.log';
Log::MultiChannel::startLogging($logfile1);
Log::MultiChannel::startLogging($logfile2);

Log::MultiChannel::mapChannel('INF',$logfile1); # Put INF messages in myLogFile1.log
Log::MultiChannel::mapChannel('ERR',$logfile1,$logfile2); # Put ERR messages in logfile1 and logfile2

Log('INF',"This is an info message for $logfile1");
Log('ERR',"This is an Error message for $logfile1 & $logfile2");

# Print out # of messages printed on each channel
Log('INF','Log Stats:');
foreach my $line (Log::MultiChannel::logStats()) { Log('INF',$line); }

Log::MultiChannel::closeLogs(); # This will close ALL log files that are open
exit;
