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

plan tests => 24;

note('from 2-by-3 to 1-by-6');

{
    my $x = Math::Matrix::Complex -> new([[1, 3, 5],
                                 [2, 4, 6]]);
    my $y = $x -> reshape(1, 6);

    is(ref($y), 'Math::Matrix::Complex', '$y is a Math::Matrix::Complex');
    is_deeply([ @$y ], [[1, 2, 3, 4, 5, 6]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5],
                        [2, 4, 6]], '$x is unmodified');
}

note('from 2-by-3 to 3-by-2');

{
    my $x = Math::Matrix::Complex -> new([[1, 3, 5],
                                 [2, 4, 6]]);
    my $y = $x -> reshape(3, 2);

    is(ref($y), 'Math::Matrix::Complex', '$y is a Math::Matrix::Complex');
    is_deeply([ @$y ], [[1, 4], [2, 5], [3, 6]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5],
                        [2, 4, 6]], '$x is unmodified');
}

note('from 2-by-3 to 6-by-1');

{
    my $x = Math::Matrix::Complex -> new([[1, 3, 5],
                                 [2, 4, 6]]);
    my $y = $x -> reshape(6, 1);

    is(ref($y), 'Math::Matrix::Complex', '$y is a Math::Matrix::Complex');
    is_deeply([ @$y ], [[1], [2], [3], [4], [5], [6]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5],
                        [2, 4, 6]], '$x is unmodified');
}

note('from 1-by-6 to 2-by-3');

{
    my $x = Math::Matrix::Complex -> new([[1, 2, 3, 4, 5, 6]]);
    my $y = $x -> reshape(2, 3);

    is(ref($y), 'Math::Matrix::Complex', '$y is a Math::Matrix::Complex');
    is_deeply([ @$y ], [[1, 3, 5],
                        [2, 4, 6]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3, 4, 5, 6]], '$x is unmodified');
}

note('from 1-by-6 to 6-by-1');

{
    my $x = Math::Matrix::Complex -> new([[1, 2, 3, 4, 5, 6]]);
    my $y = $x -> reshape(6, 1);

    is(ref($y), 'Math::Matrix::Complex', '$y is a Math::Matrix::Complex');
    is_deeply([ @$y ], [[1], [2], [3], [4], [5], [6]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3, 4, 5, 6]], '$x is unmodified');
}

note('from 6-by-1 to 2-by-3');

{
    my $x = Math::Matrix::Complex -> new([[1], [2], [3], [4], [5], [6]]);
    my $y = $x -> reshape(2, 3);

    is(ref($y), 'Math::Matrix::Complex', '$y is a Math::Matrix::Complex');
    is_deeply([ @$y ], [[1, 3, 5],
                        [2, 4, 6]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1], [2], [3], [4], [5], [6]], '$x is unmodified');
}

note('from 6-by-1 to 1-by-6');

{
    my $x = Math::Matrix::Complex -> new([[1], [2], [3], [4], [5], [6]]);
    my $y = $x -> reshape(1, 6);

    is(ref($y), 'Math::Matrix::Complex', '$y is a Math::Matrix::Complex');
    is_deeply([ @$y ], [[1, 2, 3, 4, 5, 6]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1], [2], [3], [4], [5], [6]], '$x is unmodified');
}

note('from 0-by-0 to 0-by-0');

{
    my $x = Math::Matrix::Complex -> new([]);
    my $y = $x -> reshape(0, 0);

    is(ref($y), 'Math::Matrix::Complex', '$y is a Math::Matrix::Complex');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}
