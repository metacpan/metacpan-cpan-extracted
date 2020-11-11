#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 3;

{
    my $x = Math::Matrix -> new([[ 3, -1,  5 ],
                                 [ 4,  0,  2 ],
                                 [ 2,  6, -5 ]]);
    my $y = $x -> minormatrix(1, 2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 3, -1 ],
                        [ 2,  6 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, -1,  5 ],
                        [ 4,  0,  2 ],
                        [ 2,  6, -5 ]], '$x is unmodified');
}
