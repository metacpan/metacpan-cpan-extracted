#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 8;

note('2-by-3 matrix');

{
    my $x = Math::Matrix -> new([[1, 2, 3],
                                 [4, 5, 6]]);
    my $sub = sub { $_ * 3 };
    my $y = $x -> map($sub);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 3,  6,  9],
                        [12, 15, 18]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowx, $ncolx) = $x -> size();
    for my $i (0 .. $nrowx - 1) {
        for my $j (0 .. $ncolx - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3],
                        [4, 5, 6]], '$x is unmodified');
}

note('3-by-3 matrix');

{
    my $x = Math::Matrix -> new([[1, 2, 3],
                                 [4, 5, 6],
                                 [7, 8, 9]]);
    my $sub = sub { $_[0] == $_[1] ? $_ * 3 : $_ };
    my $y = $x -> map($sub);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 3,  2,  3],
                        [ 4, 15,  6],
                        [ 7,  8, 27]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowx, $ncolx) = $x -> size();
    for my $i (0 .. $nrowx - 1) {
        for my $j (0 .. $ncolx - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3],
                        [4, 5, 6],
                        [7, 8, 9]], '$x is unmodified');
}

note("empty empty");

{
    my $x = Math::Matrix -> new([]);
    my $sub = sub { $_ * 3 };
    my $y = $x -> map($sub);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$x ], [], '$x is unmodified');
}
