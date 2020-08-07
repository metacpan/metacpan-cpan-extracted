#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 2;

my $x = Math::Matrix -> new([-2, -1, 0], [1, 2, 3]);
my $y = $x -> negative();
is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
is_deeply([ @$y ], [[  2,  1,  0 ],
                    [ -1, -2, -3 ]], '$y has the right values');
