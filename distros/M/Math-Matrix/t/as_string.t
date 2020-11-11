#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 2;

my $x = Math::Matrix -> new([[2.71828, 0.69315],
                             [1.41421, 3.14159]]);
my $s = $x -> as_string();
is(ref($s), '', '$y is a scalar');
is($s, "   2.71828    0.69315 \n   1.41421    3.14159 \n",
   '$s has the right value');
