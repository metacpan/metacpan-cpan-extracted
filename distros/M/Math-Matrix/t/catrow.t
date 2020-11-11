#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 28;

{
    my $x = Math::Matrix -> new([[1, 2],
                                 [3, 4]]);
    my $y = Math::Matrix -> new([[5, 6]]);
    my $z = $x -> catrow($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[1, 2],
                        [3, 4],
                        [5, 6]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2],
                        [3, 4]], '$x is unmodified');
    is_deeply([ @$y ], [[5, 6]], '$y is unmodified');
}

{
    my $x = Math::Matrix -> new([[0, 1],
                                 [2, 3],
                                 [4, 5]]);
    my $y = Math::Matrix -> new([[6, 7],
                                 [8, 9]]);
    my $z = $x -> catrow($y);
    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[0, 1],
                        [2, 3],
                        [4, 5],
                        [6, 7],
                        [8, 9]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[0, 1],
                        [2, 3],
                        [4, 5]], '$x is unmodified');
    is_deeply([ @$y ], [[6, 7],
                        [8, 9]], '$y is unmodified');
}

{
    my $x = Math::Matrix -> new([[0, 1],
                                 [2, 3],
                                 [4, 5]]);
    my $y = Math::Matrix -> new([]);
    my $z = $x -> catrow($y);
    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[0, 1],
                        [2, 3],
                        [4, 5]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[0, 1],
                        [2, 3],
                        [4, 5]], '$x is unmodified');
    is_deeply([ @$y ], [], '$y is unmodified');
}

{
    my $x = Math::Matrix -> new([]);
    my $a = Math::Matrix -> new([[2, 3],
                                 [4, 5]]);
    my $b = Math::Matrix -> new([]);
    my $c = Math::Matrix -> new([[6, 7]]);
    my $z = $x -> catrow($a, $b, $c);
    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 2, 3 ],
                        [ 4, 5 ],
                        [ 6, 7 ]], '$z has the right values');

    # Verify that modifying $z does not modify $x, $a, $b, or $c.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [],       '$x is unmodified');
    is_deeply([ @$a ], [[2, 3],
                        [4, 5]], '$a is unmodified');
    is_deeply([ @$b ], [],       '$b is unmodified');
    is_deeply([ @$c ], [[6, 7]], '$c is unmodified');
}

{
    my $x = Math::Matrix -> new([]);
    my $y = Math::Matrix -> new([]);
    my $z = $x -> catrow($y);
    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [], '$z has the right values');

    is_deeply([ @$x ], [], '$x is unmodified');
    is_deeply([ @$y ], [], '$y is unmodified');
}

{
    my $x = Math::Matrix -> new([[3]]);
    my $z = $x -> catrow($x, $x, $x);
    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[3], [3], [3], [3]], '$z has the right values');
    is_deeply([ @$x ], [[3]], '$x is unmodified');
}

{
    my $x = Math::Matrix -> new([[3]]);
    my $z = $x -> catrow();
    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[3]], '$z has the right values');
    is_deeply([ @$x ], [[3]], '$x is unmodified');
}
