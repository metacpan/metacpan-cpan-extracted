#!perl
#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 27;

################################################################################

note('det() on a 5-by-5 matrix');

{
    my $x = Math::Matrix -> new([[  2,  2, -7,  2,  2 ],
                                 [  0, -8,  4, -2,  8 ],
                                 [ -6, -6, -3,  6, -6 ],
                                 [  4, -2,  8, -4,  2 ],
                                 [ -4,  0, -1,  5, -6 ]]);
    my $y = $x -> det();

    is(ref($y), '', '$y is a Perl scalar');
    cmp_ok($y, '==', 6912, '$y has the right value');

    is_deeply([ @$x ], [[  2,  2, -7,  2,  2 ],
                        [  0, -8,  4, -2,  8 ],
                        [ -6, -6, -3,  6, -6 ],
                        [  4, -2,  8, -4,  2 ],
                        [ -4,  0, -1,  5, -6 ]], '$x is unmodified');
}

note('det() on a 3-by-3 matrix');

{
    my $x = Math::Matrix -> new([[ 1, 2, 3 ],
                                 [ 2, 3, 4 ],
                                 [ 3, 2, 1 ]]);
    my $y = $x -> det();

    is(ref($y), '', '$y is a Perl scalar');
    cmp_ok(abs($y), '==', 0, '$y has the right value');

    is_deeply([ @$x ], [[ 1, 2, 3 ],
                        [ 2, 3, 4 ],
                        [ 3, 2, 1 ]], '$x is unmodified');
}

note('det() on a 1-by-1 matrix');

{
    my $x = Math::Matrix -> new([[ 3 ]]);
    my $y = $x -> det();

    is(ref($y), '', '$y is a Perl scalar');
    cmp_ok(abs($y), '==', 3, '$y has the right value');

    is_deeply([ @$x ], [[ 3 ]], '$x is unmodified');
}

################################################################################

note('determinant() on a 5-by-5 matrix');

{
    my $x = Math::Matrix -> new([[  2,  2, -7,  2,  2 ],
                                 [  0, -8,  4, -2,  8 ],
                                 [ -6, -6, -3,  6, -6 ],
                                 [  4, -2,  8, -4,  2 ],
                                 [ -4,  0, -1,  5, -6 ]]);
    my $y = $x -> determinant();

    is(ref($y), '', '$y is a Perl scalar');
    cmp_ok($y, '==', 6912, '$y has the right value');

    is_deeply([ @$x ], [[  2,  2, -7,  2,  2 ],
                        [  0, -8,  4, -2,  8 ],
                        [ -6, -6, -3,  6, -6 ],
                        [  4, -2,  8, -4,  2 ],
                        [ -4,  0, -1,  5, -6 ]], '$x is unmodified');
}

note('determinant() on a 3-by-3 matrix');

{
    my $x = Math::Matrix -> new([[ 1, 2, 3 ],
                                 [ 2, 3, 4 ],
                                 [ 3, 2, 1 ]]);
    my $y = $x -> determinant();

    is(ref($y), '', '$y is a Perl scalar');
    cmp_ok(abs($y), '==', 0, '$y has the right value');

    is_deeply([ @$x ], [[ 1, 2, 3 ],
                        [ 2, 3, 4 ],
                        [ 3, 2, 1 ]], '$x is unmodified');
}

note('determinant() on a 1-by-1 matrix');

{
    my $x = Math::Matrix -> new([[ 3 ]]);
    my $y = $x -> determinant();

    is(ref($y), '', '$y is a Perl scalar');
    cmp_ok(abs($y), '==', 3, '$y has the right value');

    is_deeply([ @$x ], [[ 3 ]], '$x is unmodified');
}

################################################################################

note('detr() on a 5-by-5 matrix');

{
    my $x = Math::Matrix -> new([[  2,  2, -7,  2,  2 ],
                                 [  0, -8,  4, -2,  8 ],
                                 [ -6, -6, -3,  6, -6 ],
                                 [  4, -2,  8, -4,  2 ],
                                 [ -4,  0, -1,  5, -6 ]]);
    my $y = $x -> detr();

    is(ref($y), '', '$y is a Perl scalar');
    cmp_ok($y, '==', 6912, '$y has the right value');

    is_deeply([ @$x ], [[  2,  2, -7,  2,  2 ],
                        [  0, -8,  4, -2,  8 ],
                        [ -6, -6, -3,  6, -6 ],
                        [  4, -2,  8, -4,  2 ],
                        [ -4,  0, -1,  5, -6 ]], '$x is unmodified');
}

note('detr() on a 3-by-3 matrix');

{
    my $x = Math::Matrix -> new([[ 1, 2, 3 ],
                                 [ 2, 3, 4 ],
                                 [ 3, 2, 1 ]]);
    my $y = $x -> detr();

    is(ref($y), '', '$y is a Perl scalar');
    cmp_ok(abs($y), '==', 0, '$y has the right value');

    is_deeply([ @$x ], [[ 1, 2, 3 ],
                        [ 2, 3, 4 ],
                        [ 3, 2, 1 ]], '$x is unmodified');
}

note('detr() on a 1-by-1 matrix');

{
    my $x = Math::Matrix -> new([[ 3 ]]);
    my $y = $x -> detr();

    is(ref($y), '', '$y is a Perl scalar');
    cmp_ok(abs($y), '==', 3, '$y has the right value');

    is_deeply([ @$x ], [[ 3 ]], '$x is unmodified');
}
