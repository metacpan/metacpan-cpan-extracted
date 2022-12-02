#!/usr/bin/env perl
use 5.012;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use FASTX::ReaderPaired;
use Data::Dumper;

print "PE: $FASTX::ReaderPaired::VERSION\n";

my $i = 0;
my $PE = FASTX::ReaderPaired->new({ filename => "$ARGV[0]", interleaved => $i});

say Dumper $PE;
my $c = 0;
while (my $pe = $PE->getReads()) {
  say Dumper $pe if ($c == 0);
  $c++;

}
