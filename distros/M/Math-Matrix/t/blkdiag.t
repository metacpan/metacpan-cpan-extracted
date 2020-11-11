#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 14;

{
    my $x = [[2]];
    my $y = [[3, 4]];
    my $z = [[5],[6]];

    my $w = Math::Matrix -> blkdiag($x, $y, $z);

    is(ref($w), 'Math::Matrix', '$w is a Math::Matrix');
    is_deeply([ @$w ], [[2, 0, 0, 0],
                        [0, 3, 4, 0],
                        [0, 0, 0, 5],
                        [0, 0, 0, 6]], '$w has the right values');

    # Verify that modifying $w does not modify $x, $y, or $z.

    my ($nroww, $ncolw) = $w -> size();
    for my $i (0 .. $nroww - 1) {
        for my $j (0 .. $ncolw - 1) {
            $w -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[2]], '$x is unmodified');
    is_deeply([ @$y ], [[3, 4]], '$y is unmodified');
    is_deeply([ @$z ], [[5],[6]], '$z is unmodified');
}

{
    my $x = Math::Matrix -> new([[2]]);
    my $y = Math::Matrix -> new([[3, 4]]);
    my $z = Math::Matrix -> new([[5],[6]]);

    my $w = Math::Matrix -> blkdiag($x, $y, $z);

    is(ref($w), 'Math::Matrix', '$w is a Math::Matrix');
    is_deeply([ @$w ], [[2, 0, 0, 0],
                        [0, 3, 4, 0],
                        [0, 0, 0, 5],
                        [0, 0, 0, 6]], '$w has the right values');

    # Verify that modifying $w does not modify $x, $y, or $z.

    my ($nroww, $ncolw) = $w -> size();
    for my $i (0 .. $nroww - 1) {
        for my $j (0 .. $ncolw - 1) {
            $w -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[2]], '$x is unmodified');
    is_deeply([ @$y ], [[3, 4]], '$y is unmodified');
    is_deeply([ @$z ], [[5],[6]], '$z is unmodified');
}

{
    my $w = Math::Matrix -> blkdiag(2, 3, 4);

    is(ref($w), 'Math::Matrix', '$w is a Math::Matrix');
    is_deeply([ @$w ], [[2, 0, 0],
                        [0, 3, 0],
                        [0, 0, 4]], '$w has the right values');
}

{
    my $w = Math::Matrix -> blkdiag();

    is(ref($w), 'Math::Matrix', '$w is a Math::Matrix');
    is_deeply([ @$w ], [], '$w has the right values');
}
