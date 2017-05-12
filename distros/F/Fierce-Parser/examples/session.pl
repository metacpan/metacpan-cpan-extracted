#!/usr/bin/perl -w
# $Id: session.pl 295 2009-11-16 04:35:00Z jabra $ 
#  
# Session example script
#
# Example: 
#
#   ./session.pl test1.xml
#   Scan Options:               -dns thisisjustfortestingfierce.com -format xml -output result.xml
#   Start Scan in unixtime:     1220494203
#   Start Scan:                 Wed Sep  3 22:10:03 2008
#   Stop Scan in unixtime:      1220494203
#   Stop Scan:                  Wed Sep  3 22:10:03 2008
#   Elasp Time:                 0

use strict;
use Fierce::Parser;
my $fp = new Fierce::Parser;
if (defined($ARGV[0])){
    my $file = $ARGV[0];
    my $parser = $fp->parse_file($file);
    my $session    = $parser->session();

    print "Scan Options:\t\t\t" . $session->options . "\n";
    print "Start Scan in unixtime:\t\t" . $session->startscan . "\n";
    print "Start Scan:\t\t\t" . $session->startscanstr . "\n";

    print "Stop Scan in unixtime:\t\t" . $session->endscan . "\n";
    print "Stop Scan:\t\t\t" . $session->endscanstr . "\n";

    print "Elasp Time:\t\t\t" . $session->elapsedtime . "\n";
}
else {
    print "Usage: $0 [fierce-xml]\n";
}
