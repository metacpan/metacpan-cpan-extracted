#!/usr/bin/perl
#
# gettext.pl
#
# Last updated by gossamer on Sat Feb 21 18:50:31 EST 1998
#
# Last updated by gossamer on Wed Jan 28 21:47:21 EST 1998
#

use HyperWave::CSP;

#
# Main starts here
#

my $path = shift;

my $host = "xanadu.com.au";

my $HyperWave = HyperWave::CSP->new($host);
$objnum = $HyperWave->get_objnum_by_name($path);

print $HyperWave->get_text($objnum);

exit 1;
#
# End.
#
