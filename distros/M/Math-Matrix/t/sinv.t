#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 6;

note('sinv() on a 2-by-3 matrix');

{
    my $x = Math::Matrix -> new([[ 1,  2,  4],
                                 [-1, -2, -4]]);
    my $y = $x -> sinv();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 1,  0.5,  0.25],
                        [-1, -0.5, -0.25]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 1,  2,  4],
                        [-1, -2, -4]], '$x is unmodified');
}

note('sinv() on an empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> sinv();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');

    is_deeply([ @$x ], [], '$x is unmodified');
}
