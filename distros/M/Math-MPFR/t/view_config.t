use strict;
use warnings;

print "1..1\n";

warn "\n No tests here - just output (if any) from any configuration\n",
     " probing that was done during the 'perl Makefile.PL' step\n\n";

my $RD;

my $save = open $RD, '<', 'save_config.txt';

warn "Couldn't open save_config.txt for reading: $!\n"
  unless $save;

if($save) {
  while(<$RD>) {
    chomp;
    warn "$_\n";
  }
  close($RD);
}

print "ok 1\n";

