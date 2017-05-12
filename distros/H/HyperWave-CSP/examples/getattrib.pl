#!/usr/bin/perl
#
# get_attributes.pl
#
# Last updated by gossamer on Sat Feb 21 18:54:55 EST 1998
#

use HyperWave::CSP;

#
# Main starts here
#

my $path = shift;

my $host = "xanadu.com.au";

my $HyperWave = HyperWave::CSP->new($host);
$objnum = $HyperWave->get_objnum_by_name($path);

my %attributes = $HyperWave->get_attributes_hash($objnum);

foreach $attrib (sort keys %attributes) {
   print "$attrib = $attributes{$attrib}\n";   
}

exit 1;
#
# End.
#
