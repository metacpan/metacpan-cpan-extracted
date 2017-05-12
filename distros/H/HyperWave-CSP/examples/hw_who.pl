#!/usr/bin/perl
#
# Gets a 'who' list from the server, then disconnects.
#
# Last updated by gossamer on Sat Feb 21 19:01:54 EST 1998
#

use HyperWave::CSP;

#
# Main starts here
#

my $host = "xanadu.com.au";

my $HyperWave = HyperWave::CSP->new($host);

print $HyperWave->command_who();

exit 1;
#
# End.
#
