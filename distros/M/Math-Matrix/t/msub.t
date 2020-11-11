#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 6;

note("msub() with two matrices");

{
    my $x = Math::Matrix -> new([[ 5, -2,  4],
                                 [-1,  3, -2]]);
    my $y = Math::Matrix -> new([[ 4,  3,  2],
                                 [-1, -2,  6]]);
    my $z = $x -> msub($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 1, -5,  2],
                        [ 0,  5, -8]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 5, -2,  4],
                        [-1,  3, -2]], '$x is unmodified');
    is_deeply([ @$y ], [[ 4,  3,  2],
                        [-1, -2,  6]], '$y is unmodified');
}

note("msub() with empty matrices");

{
    my $x = Math::Matrix -> new([]);
    my $y = Math::Matrix -> new([]);
    my $z = $x -> msub($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [], '$z has the right values');
}
