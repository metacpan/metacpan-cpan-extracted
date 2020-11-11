#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 6;

note('rot180()');

{
    my $x = Math::Matrix -> new([[1, 2, 3],
                                 [4, 5, 6]]);
    my $y = $x -> rot180();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[6, 5, 4],
                        [3, 2, 1]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3],
                        [4, 5, 6]], '$x is unmodified');
}

note('rot180() with empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> rot180();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}
