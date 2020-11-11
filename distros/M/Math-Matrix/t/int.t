#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 12;

note('int() on a non-empty matrix');

{
    my $x = Math::Matrix -> new([[ -1.25, -2.56,  3.13 ],
                                 [  4.18,  5.12, -6.25 ]]);
    my $y = $x -> int();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ -1, -2,  3 ],
                        [  4,  5, -6 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ -1.25, -2.56,  3.13 ],
                        [  4.18,  5.12, -6.25 ]], '$x is unmodified');
}

note('int() on an empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> int();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}

note('overloading');

{
    my $x = Math::Matrix -> new([[ -1.25, -2.56,  3.13 ],
                                 [  4.18,  5.12, -6.25 ]]);
    my $y = int $x;

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ -1, -2,  3 ],
                        [  4,  5, -6 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ -1.25, -2.56,  3.13 ],
                        [  4.18,  5.12, -6.25 ]], '$x is unmodified');
}

{
    my $x = Math::Matrix -> new([]);
    my $y = int $x;

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}
