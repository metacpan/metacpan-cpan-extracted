use strict;
use warnings;

exit 0 unless scalar(@ARGV) && ($ARGV[0] eq 'interactive');

undef($ENV{LESS});

my @fail;
for (sort glob "t/*interactive.t") {
  print "Running $_...\n";
  push @fail, $_ if system($^X, '-Mblib', $_);
}
print scalar @fail ? "\nSome tests failed: @fail\n" : "\nSuccess!\n";
