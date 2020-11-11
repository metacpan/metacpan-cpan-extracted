#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Math::Matrix::Real;

plan tests => 21;

note("one non-empty operand");

{
    my $x = Math::Matrix::Real -> new([[1, 2, 3],
                                       [4, 5, 6]]);
    my $sub = sub { $_[0] * 3 };
    my $y = $x -> sapply($sub);

    is(ref($y), 'Math::Matrix::Real', '$y is a Math::Matrix::Real');
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

note("two non-empty operands with the same size");

{
    my $x = Math::Matrix::Real -> new([[1, 2, 3]]);
    my $y = Math::Matrix::Real -> new([[4, 5, 6]]);
    my $sub = sub { $_[0] * $_[1] };
    my $z = $x -> sapply($sub, $y);

    is(ref($z), 'Math::Matrix::Real', '$z is a Math::Matrix::Real');
    is_deeply([ @$z ], [[4, 10, 18]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3]], '$x is unmodified');
    is_deeply([ @$y ], [[4, 5, 6]], '$y is unmodified');
}

note("three non-empty operands with the same size");

{
    my $x = Math::Matrix::Real -> new([[1, 2, 3]]);
    my $y = Math::Matrix::Real -> new([[4, 5, 6]]);
    my $z = Math::Matrix::Real -> new([[7, 8, 9]]);
    my $sub = sub { $_[0] * $_[1] + $_[2] };
    my $w = $x -> sapply($sub, $y, $z);

    is(ref($w), 'Math::Matrix::Real', '$w is a Math::Matrix::Real');
    is_deeply([ @$w ], [[11, 18, 27]], '$w has the right values');

    # Verify that modifying $w does not modify $x, $y, or $z.

    my ($nroww, $ncolw) = $w -> size();
    for my $i (0 .. $nroww - 1) {
        for my $j (0 .. $ncolw - 1) {
            $w -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3]], '$x is unmodified');
    is_deeply([ @$y ], [[4, 5, 6]], '$y is unmodified');
    is_deeply([ @$z ], [[7, 8, 9]], '$z is unmodified');
}

note("two non-empty operands with different size");

{
    my $x = Math::Matrix::Real -> new([[1, 2, 3]]);
    my $y = Math::Matrix::Real -> new([[4], [5], [6]]);
    my $sub = sub { $_[0] * $_[1] };
    my $z = $x -> sapply($sub, $y);

    is(ref($z), 'Math::Matrix::Real', '$z is a Math::Matrix::Real');
    is_deeply([ @$z ], [[4,  8, 12],
                        [5, 10, 15],
                        [6, 12, 18]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3]], '$x is unmodified');
    is_deeply([ @$y ], [[4], [5], [6]], '$y is unmodified');
}

note("one empty operand");

{
    my $x = Math::Matrix::Real -> new([]);
    my $sub = sub { $_[0] * 3 };
    my $y = $x -> sapply($sub);

    is(ref($y), 'Math::Matrix::Real', '$y is a Math::Matrix::Real');
    is_deeply([ @$x ], [], '$x is unmodified');
}

note("two empty operands");

{
    my $x = Math::Matrix::Real -> new([]);
    my $y = Math::Matrix::Real -> new([]);
    my $sub = sub { $_[0] * $_[1] };
    my $z = $x -> sapply($sub);

    is(ref($z), 'Math::Matrix::Real', '$z is a Math::Matrix::Real');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}
