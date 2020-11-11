#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 5;

{
    my $x = Math::Matrix -> new([[1, 2, 3, 4],
                                 [5, 6, 7, 8]]);
    my $y = $x -> fliplr();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[4, 3, 2, 1],
                        [8, 7, 6, 5]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3, 4],
                        [5, 6, 7, 8]], '$x is unmodified');
}

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> fliplr();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [],
              '$y has the right values');
}
