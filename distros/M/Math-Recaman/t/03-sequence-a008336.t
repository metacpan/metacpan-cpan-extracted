#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Math::Recaman;

my @sequence = @Math::Recaman::a008336_checks;
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