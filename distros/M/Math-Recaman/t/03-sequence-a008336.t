#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Math::Recaman;

my @sequence = (1, 1, 2, 6, 24, 120, 20, 140, 1120, 10080, 1008, 11088, 924,
                12012, 858, 12870, 205920, 3500640, 194480, 3695120,
                184756, 3879876, 176358, 4056234, 97349616, 2433740400,
                93605400, 2527345800, 90262350, 2617608150, 87253605,
                2704861755, 86555576160, 2856334013280);
my $size = scalar(@sequence);

plan tests => $size+2;

is(Math::Recaman::recaman_a008336(0), 0, "Correctly got 0 back for invalid input");
Math::Recaman::recaman_a008336($size, sub {
  my $got      = shift;
  my $count    = shift;
  my $expected = shift @sequence;
  is($got, $expected, "Number $count of the sequence is $expected");
});
is(scalar(@sequence), 0, "We exhausted our list");