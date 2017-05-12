use strict;
use warnings;

print "1..1\n";

warn "\n\n  No tests with this file. Instead, mainly for the benefit\n",
       "  of the author, we (hopefully) see some diagnostics from some\n",
       "  test executables that were run during the Makefile.PL stage.\n\n";

my $file = './myconfig.log';
$file = '../myconfig.log' if -e '../myconfig.log';

my $open = open RD, '<', $file;

if($open) {warn $_ while(<RD>)}
else {warn "Failed to open $file for reading: $!\n"}

if($open) {close RD or warn "Failed to close $file after reading: $!\n"}

warn "\n";
print "ok 1\n";
