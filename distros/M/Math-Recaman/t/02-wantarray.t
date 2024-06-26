#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Math::Recaman qw(recaman);

my @sequence = (0, 1, 3, 6, 2, 7, 13, 20, 12, 21);
my $size = scalar(@sequence);

plan tests => 3;
my @numbers;
ok(@numbers = recaman($size), "Called function correctly");
is(scalar(@numbers), $size,   "Got the right size back");
is_deeply(\@numbers, \@sequence, "Got the right numbers");
