#!perl

use strict;
use warnings;

use Test::More;

# Ensure a recent version of Math::Complex. Math Complex didn't support any way
# of cloning/copying Math::Complex objects before version 1.57.

my $min_math_complex_ver = 1.57;
eval "use Math::Complex $min_math_complex_ver";
plan skip_all => "Math::Complex $min_math_complex_ver required" if $@;

use lib 't/lib';
use Math::Matrix::Complex;

plan tests => 26;

{
    my $x = Math::Matrix::Complex -> new([[1, 2],
                                          [4, 5]]);
    my $y = Math::Matrix::Complex -> new([[3],
                                          [6]]);
    my $z = $x -> catcol($y);

    is(ref($z), 'Math::Matrix::Complex', '$z is a Math::Matrix::Complex');
    is_deeply([ @$z ], [[1, 2, 3],
                        [4, 5, 6]], '$z has the right values');

    is_deeply([ @$x ], [[1, 2],
                        [4, 5]], '$x is unmodified');
    is_deeply([ @$y ], [[3],
                        [6]], '$y is unmodified');
}

{
    my $x = Math::Matrix::Complex -> new([[0, 1, 2],
                                          [5, 6, 7]]);
    my $y = Math::Matrix::Complex -> new([[3, 4],
                                          [8, 9]]);
    my $z = $x -> catcol($y);
    is(ref($z), 'Math::Matrix::Complex', '$z is a Math::Matrix::Complex');
    is_deeply([ @$z ], [[0, 1, 2, 3, 4],
                        [5, 6, 7, 8, 9]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[0, 1, 2],
                        [5, 6, 7]], '$x is unmodified');
    is_deeply([ @$y ], [[3, 4],
                        [8, 9]], '$y is unmodified');
}

{
    my $x = Math::Matrix::Complex -> new([[0, 1, 2],
                                          [5, 6, 7]]);
    my $y = Math::Matrix::Complex -> new([]);
    my $z = $x -> catcol($y);
    is(ref($z), 'Math::Matrix::Complex', '$z is a Math::Matrix::Complex');
    is_deeply([ @$z ], [[0, 1, 2],
                        [5, 6, 7]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[0, 1, 2],
                        [5, 6, 7]], '$x is unmodified');
    is_deeply([ @$y ], [], '$y is unmodified');
}

{
    my $x = Math::Matrix::Complex -> new([]);
    my $y = Math::Matrix::Complex -> new([[3, 4],
                                          [8, 9]]);
    my $z = $x -> catcol($y);
    is(ref($z), 'Math::Matrix::Complex', '$z is a Math::Matrix::Complex');
    is_deeply([ @$z ], [[3, 4],
                        [8, 9]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [], '$x is unmodified');
    is_deeply([ @$y ], [[3, 4],
                        [8, 9]], '$y is unmodified');
}

{
    my $x = Math::Matrix::Complex -> new([]);
    my $y = Math::Matrix::Complex -> new([]);
    my $z = $x -> catcol($y);
    is(ref($z), 'Math::Matrix::Complex', '$z is a Math::Matrix::Complex');
    is_deeply([ @$z ], [], '$z has the right values');

    is_deeply([ @$x ], [], '$x is unmodified');
    is_deeply([ @$y ], [], '$y is unmodified');
}

{
    my $x = Math::Matrix::Complex -> new([[3]]);
    my $z = $x -> catcol($x, $x, $x);
    is(ref($z), 'Math::Matrix::Complex', '$z is a Math::Matrix::Complex');
    is_deeply([ @$z ], [[3, 3, 3, 3]], '$z has the right values');
    is_deeply([ @$x ], [[3]], '$x is unmodified');
}

{
    my $x = Math::Matrix::Complex -> new([[3]]);
    my $z = $x -> catcol();
    is(ref($z), 'Math::Matrix::Complex', '$z is a Math::Matrix::Complex');
    is_deeply([ @$z ], [[3]], '$z has the right values');
    is_deeply([ @$x ], [[3]], '$x is unmodified');
}
