#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 10;

my $x;

$x = Math::Matrix -> exchg(0);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [], '$x has the right values');

$x = Math::Matrix -> exchg(1);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[1]], '$x has the right values');

$x = Math::Matrix -> exchg(2);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[0, 1],
                    [1, 0]], '$x has the right values');

$x = Math::Matrix -> exchg(3);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[0, 0, 1],
                    [0, 1, 0],
                    [1, 0, 0]], '$x has the right values');

$x = Math::Matrix -> exchg(4);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[0, 0, 0, 1],
                    [0, 0, 1, 0],
                    [0, 1, 0, 0],
                    [1, 0, 0, 0]], '$x has the right values');
