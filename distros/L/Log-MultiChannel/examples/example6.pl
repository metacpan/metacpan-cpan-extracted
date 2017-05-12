#!/usr/bin/perl
# Example 6: Using a provided filehandle, and a custom log function
# If you do this, the log cycle functions are disabled.
#
# Example output:
# $ more example6.log 
# 1406668068,"INF","This is an info message for myLogFile1.log","one","two","three","Tue Jul 29 17:07:48 2014"
use strict;
use Log::MultiChannel qw(Log);
my $filename='example6.log';
open (my $fh,">$filename") or die("Unable to open $filename");

Log::MultiChannel::startLoggingOnHandle('My very own file',$fh,\&eventLogger);

Log('INF','This is an info message for myLogFile1.log','one','two','three');

Log::MultiChannel::closeLogs(); # This will close ALL log files that are open
exit;

# This is a special logging routine for events, to save
# them in an easily parsed CSV file
# These are the args:
# 0 - Epoch Time
# 1 - Local Time as a string
# 2 - Real Filehandle
# 3 - The Log object
# 4 - source module
# 5 - source filename
# 6 - source line #
# 7 - desired color
# 8 - channel name
# 9 - message
# 10 - extra field 1
# 11 - extra field 2
# 12 - extra field 3

sub eventLogger {
    my $fh=$_[2];
    my $fhObject=$_[3];
      
    # Print the line content
    print $fh "$_[0],";
    for (my $i=8;$i<13;$i++) {
	print $fh "\"$_[$i]\",";
    }
    print $fh "\"$_[1]\"\n";        
}

