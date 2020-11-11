#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 14;

note('$x -> delcol(1);');

{
    my $x = Math::Matrix -> new([[  1,  2,  3,  4 ],
                                 [  5,  6,  7,  8 ],
                                 [  9, 10, 11, 12 ],
                                 [ 13, 14, 15, 16 ]]);
    my $y = $x -> delcol(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[  1,  3,  4 ],
                        [  5,  7,  8 ],
                        [  9, 11, 12 ],
                        [ 13, 15, 16 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  1,  2,  3,  4 ],
                        [  5,  6,  7,  8 ],
                        [  9, 10, 11, 12 ],
                        [ 13, 14, 15, 16 ]], '$x is unmodified');
}

note('$x -> delcol([3, 1]);');

{
    my $x = Math::Matrix -> new([[  1,  2,  3,  4 ],
                                 [  5,  6,  7,  8 ],
                                 [  9, 10, 11, 12 ],
                                 [ 13, 14, 15, 16 ]]);
    my $y = $x -> delcol([3, 1]);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[  1,  3 ],
                        [  5,  7 ],
                        [  9, 11 ],
                        [ 13, 15 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  1,  2,  3,  4 ],
                        [  5,  6,  7,  8 ],
                        [  9, 10, 11, 12 ],
                        [ 13, 14, 15, 16 ]], '$x is unmodified');
}

note('$x -> delcol([]);');

{
    my $x = Math::Matrix -> new([[  1,  2,  3,  4 ],
                                 [  5,  6,  7,  8 ],
                                 [  9, 10, 11, 12 ],
                                 [ 13, 14, 15, 16 ]]);
    my $y = $x -> delcol([]);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[  1,  2,  3,  4 ],
                        [  5,  6,  7,  8 ],
                        [  9, 10, 11, 12 ],
                        [ 13, 14, 15, 16 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  1,  2,  3,  4 ],
                        [  5,  6,  7,  8 ],
                        [  9, 10, 11, 12 ],
                        [ 13, 14, 15, 16 ]], '$x is unmodified');
}

note('$x -> delcol([0, 1, 2, 3]);');

{
    my $x = Math::Matrix -> new([[  1,  2,  3,  4 ],
                                 [  5,  6,  7,  8 ],
                                 [  9, 10, 11, 12 ],
                                 [ 13, 14, 15, 16 ]]);
    my $y = $x -> delcol([0, 1, 2, 3]);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [],
              '$y has the right values');
}

note('$x -> delcol([3.14, 1.25]);');

{
    my $x = Math::Matrix -> new([[  1,  2,  3,  4 ],
                                 [  5,  6,  7,  8 ],
                                 [  9, 10, 11, 12 ],
                                 [ 13, 14, 15, 16 ]]);
    my $y = $x -> delcol([3.14, 1.25]);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[  1,  3 ],
                        [  5,  7 ],
                        [  9, 11 ],
                        [ 13, 15 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  1,  2,  3,  4 ],
                        [  5,  6,  7,  8 ],
                        [  9, 10, 11, 12 ],
                        [ 13, 14, 15, 16 ]], '$x is unmodified');
}
