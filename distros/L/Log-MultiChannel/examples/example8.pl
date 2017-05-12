#!/usr/bin/perl
# Example 8:  This will tee (copy) the output that is sent to a log file
# to STDOUT, so it can be seen as the program runs.
use strict;
use warnings;
use Log::MultiChannel qw(Log);

Log::MultiChannel::startLogging('myLogFile1.log');
Log::MultiChannel::startLoggingOnHandle('STDOUT',\*STDOUT);

Log::MultiChannel::mapChannel('INF','myLogFile1.log','STDOUT'); # Put INF messages in myLogFile1.log

Log('INF','This is an Error message for myLogFile1.log, that will also be printed on STDOUT');

Log::MultiChannel::closeLogs(); # This will close ALL log files that are open
exit;
