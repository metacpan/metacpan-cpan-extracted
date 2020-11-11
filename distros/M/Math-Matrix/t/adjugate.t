#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 6;

{
    my $x = Math::Matrix -> new([[ 3, -1,  5 ],
                                 [ 4,  0,  2 ],
                                 [ 2,  6, -5 ]]);
    my $y = $x -> adjugate();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ -12,  25,  -2 ],
                        [  24, -25,  14 ],
                        [  24, -20,   4 ]], '$y has the right values');

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

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> adjugate();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');

    is_deeply([ @$x ], [], '$x is unmodified');
}
