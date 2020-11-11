#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 5;

{
    my $x = Math::Matrix -> new([[1, 3, 5, 7],
                                 [2, 4, 6, 8]]);
    my $y = $x -> to_row();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 2, 3, 4, 5, 6, 7, 8]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5, 7],
                        [2, 4, 6, 8]], '$x is unmodified');
}

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> to_row();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [],
              '$y has the right values');
}
