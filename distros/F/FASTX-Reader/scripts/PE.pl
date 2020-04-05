#!/usr/bin/env perl
use 5.012;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use FASTX::PE;
use Data::Dumper;

print "PE: $FASTX::PE::VERSION\n";

my $i = 0;
my $PE = FASTX::PE->new({ filename => "$ARGV[0]", interleaved => $i});

say Dumper $PE;
while (my $pe = $PE->getReads()) {
  say Dumper $pe;
  last;
}
