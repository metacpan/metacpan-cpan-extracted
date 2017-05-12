#!/usr/bin/perl
# Example 9: Copy two logged channels to STDOUT, 
#            and make errors appear in RED
use strict;
use warnings;
use Term::ANSIColor qw(:constants);
use Log::MultiChannel qw(Log);
my $logfile='example8-inf.log';

Log::MultiChannel::startLogging($logfile);
Log::MultiChannel::startLoggingOnHandle('STDOUT',*STDOUT);

Log::MultiChannel::mapChannel('INF',$logfile,'STDOUT'); # Put INF messages in myLogFile1.log, and print to STDOUT
Log::MultiChannel::mapChannel('ERR',$logfile,'STDOUT'); # Put ERR messages in myLogFile1.log, and print to STDOUT

# Enable color on STDOUT, and assign RED to errors
Log::MultiChannel::enableColor('STDOUT');
Log::MultiChannel::assignColorCode('ERR', RED );
Log::MultiChannel::assignColorCode('INF',RESET);

Log('INF',"This is an info message for $logfile.");
Log('ERR',"This is an error message for $logfile. It will appear RED on STDOUT (but not in the log).");
Log('INF',"This is an another info message for $logfile.");

Log::MultiChannel::closeLogs(); # This will close ALL log files that are open
exit (0);
