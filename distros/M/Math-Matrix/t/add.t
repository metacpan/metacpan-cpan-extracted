#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 20;

note("add() with matrices");

{
    my $x = Math::Matrix -> new([[  1,  2,  3 ],
                                 [  4,  5,  6 ]]);
    my $y = Math::Matrix -> new([[  7,  8,  9 ],
                                 [ 10, 11, 12 ]]);
    my $z = $x -> add($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[  8, 10, 12 ],
                        [ 14, 16, 18 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  1,  2,  3 ],
                        [  4,  5,  6 ]], '$x is unmodified');
    is_deeply([ @$y ], [[  7,  8,  9 ],
                        [ 10, 11, 12 ]], '$y is unmodified');
}

note("add() with matrix and scalar");

{
    my $x = Math::Matrix -> new([[ 1, 2, 3 ],
                                 [ 4, 5, 6 ]]);
    my $y = Math::Matrix -> new([[ 7 ]]);
    my $z = $x -> add($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[  8,  9, 10 ],
                        [ 11, 12, 13 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 1, 2, 3 ],
                        [ 4, 5, 6 ]], '$x is unmodified');
    is_deeply([ @$y ], [[ 7 ]], '$y is unmodified');
}

note("add() with scalar and matrix");

{
    my $x = Math::Matrix -> new([[ 7 ]]);
    my $y = Math::Matrix -> new([[ 1, 2, 3 ],
                                 [ 4, 5, 6 ]]);
    my $z = $x -> add($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[  8,  9, 10 ],
                        [ 11, 12, 13 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 7 ]], '$x is unmodified');
    is_deeply([ @$y ], [[ 1, 2, 3 ],
                        [ 4, 5, 6 ]], '$y is unmodified');
}

note("add() with empty matrices");

{
    my $x = Math::Matrix -> new([]);
    my $y = Math::Matrix -> new([]);
    my $z = $x -> add($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [],
              '$z has the right values');
}

note("overloading");

{
    my $x = Math::Matrix -> new([[3]]);
    my $y = $x + 4;
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[7]],
              '$y has the right values');
}

{
    my $x = Math::Matrix -> new([[3]]);
    my $y = 4 + $x;
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[7]],
              '$y has the right values');
}

{
    my $x = Math::Matrix -> new([[3]]);
    $x += 4;
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [[7]],
              '$x has the right values');
}
