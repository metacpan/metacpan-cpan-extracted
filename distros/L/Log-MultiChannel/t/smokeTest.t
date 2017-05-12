#!/usr/bin/perl
use strict;
use Test::More tests => 13; 
use Term::ANSIColor qw(:constants);

my $logname0='smokeTest0.log';
my $logname1='smokeTest1.log';
my $logname2='smokeTest2.log';
my $logname3='smokeTest3.log';
my $logname4='smokeTest4.log';

# Test 1
BEGIN {
    use_ok('Log::MultiChannel',qw(Log));
}

# Test 2 - Open a log
my $fh=Log::MultiChannel::startLogging($logname0);
isnt( $fh, '',"Got a filehandle" );

# Test 3 - Did the log get created?
if (-f $logname0) { pass("Log File exists."); } else { fail("Log File does not exist."); }

# Test 4 - Did the log get the last message
Log('INF','This is a test.');
checkLogLines($logname0,2);

# Test 5 - Send an error
Log('ERR','This is a error.');
checkLogLines($logname0,3);

# Test 5a - Send an error
Log('ERR');
checkLogLines($logname0,4);

# Test 6 - Open two more logs
Log::MultiChannel::startLogging($logname1);
Log::MultiChannel::startLogging($logname2);

# Test 7 - Map INF to smokeTest1.log, and ERR to smokeTest1.log & smokeTest2.log
Log::MultiChannel::mapChannel('INF',$logname1); # Put INF messages in myLogFile1.log
Log::MultiChannel::mapChannel('ERR',$logname1); # Put ERR messages in myLogFile1.log
Log::MultiChannel::mapChannel('ERR',$logname2); # ALSO put ERR messages in myLogFile2.log

Log('INF','This is an info message for smokeTest1.log');
Log('ERR','This is an error message for smokeTest1.log & smokeTest2.log');

checkLogLines($logname1,3);
checkLogLines($logname2,2);

# Test 8 - disable and enable a channel
Log::MultiChannel::disableChannel('INF');
Log('INF','This is an info message for smokeTest1.log');
Log::MultiChannel::enableChannel('INF');
# There should be no change in the number of log lines
checkLogLines($logname1,3);

# Test 9 - This should print a warning, because the channel was not mapped first
Log::MultiChannel::disableChannel('Blah');

# Test 10 - Map to STDOUT, enable color and use the simple log handler
eval { 
    Log::MultiChannel::startLogging('STDOUT',\&Log::MultiChannel::logPrintSimple,10); 
    Log::MultiChannel::mapChannel('INF','STDOUT'); # Put INF messages in myLogFile1.log
    Log::MultiChannel::enableColor('STDOUT');
    Log::MultiChannel::assignColorCode('REM',GREEN);
    Log::MultiChannel::assignColorCode('ERR',RED);
    Log('REM',"This is a comment in green on STDOUT.");
    Log('ERR',"This is an error in red on STDOUT.");
};
if ($@) { 
    fail("STDOUT print does not appear to have worked."); 
    print STDERR "Error:$_" foreach ($@);  
} 
else {     
    pass("STDOUT print appears to have worked."); 
}

# Test 11 - Make sure there's no more messages printed following a close
Log::MultiChannel::startLogging($logname4);
Log::MultiChannel::mapChannel('INF',$logname4); # Put INF messages in log 4
Log::MultiChannel::closeLogs(); # This will close ALL log files that are open
checkLogLines($logname4,0); # There should be 0 lines in the log

# Test 12 - Make sure we can unmap a channel from a log
Log::MultiChannel::startLogging($logname4);
Log::MultiChannel::mapChannel('INF',$logname4); # Put INF messages in log 4
Log('INF','The INF channel is mapped.');
Log::MultiChannel::unmapChannel('INF',$logname4); # Put INF messages in log 4
Log('INF','The INF channel is not mapped.');
Log::MultiChannel::mapChannel('INF',$logname4); # Put INF messages in log 4
Log('INF','The INF channel is mapped again.');
checkLogLines($logname4,3); # There should be 0 lines in the log

# Test 13 - Change the print handler for a log.
Log::MultiChannel::setPrintHandler($logname4,'Log::MultiChannel::logPrint');
Log('INF','This is the logPrint handler.');
Log::MultiChannel::setPrintHandler($logname4,'Log::MultiChannel::logPrintSimple');
Log('INF','This is the logPrintSimple handler.');
Log::MultiChannel::setPrintHandler($logname4,'Log::MultiChannel::logPrintVerbose');
Log('INF','This is the logPrintVerbose handler.');
checkLogLines($logname4,6);
exit 0;

# This will check the number of lines in a log
# On *nix I would have used wc, but that doesn't work
# on Windows.
sub checkLogLines {
    my $logname=shift;
    my $expectedLineCount=shift;
    open (FILEIN,$logname) or BAIL_OUT("Unable to read log file $logname to check it. Something has gone wrong.");
    my $lineCount=0;
    while (<FILEIN>) {
	chomp(my $line=$_);
	$lineCount++;
    }
    close(FILEIN);

    ok(($lineCount eq $expectedLineCount), "Log should have $expectedLineCount line - got: ($lineCount).");
}

