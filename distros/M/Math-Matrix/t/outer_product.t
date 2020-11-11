#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 4;

my $x = Math::Matrix -> new([1, 2, 3]);
my $y = Math::Matrix -> new([4, 5, 6, 7]);
my $p = $x -> outer_product($y);

is(ref($p), 'Math::Matrix', '$p is a Math::Matrix');
is_deeply([ @$p ], [[  4,  5,  6,  7 ],
                    [  8, 10, 12, 14 ],
                    [ 12, 15, 18, 21 ]], '$p has the right values');

# Verify that modifying $p does not modify $x or $y.

my ($nrowp, $ncolp) = $p -> size();
for my $i (0 .. $nrowp - 1) {
    for my $j (0 .. $ncolp - 1) {
        $p -> [$i][$j] += 100;
    }
}

is_deeply([ @$x ], [[ 1, 2, 3 ]],, '$x is unmodified');
is_deeply([ @$y ], [[ 4, 5, 6, 7 ]],, '$y is unmodified');
