#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 12;

my $x;

$x = Math::Matrix -> scalar(7);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[7]], '$x has the right values');

$x = Math::Matrix -> scalar(7, 0);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [], '$x has the right values');

$x = Math::Matrix -> scalar(7, 1);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[7]], '$x has the right values');

$x = Math::Matrix -> scalar(7, 2);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[7, 0],
                    [0, 7]], '$x has the right values');

$x = Math::Matrix -> scalar(7, 3);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[7, 0, 0],
                    [0, 7, 0],
                    [0, 0, 7]], '$x has the right values');

$x = Math::Matrix -> scalar(7, 3, 3);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[7, 0, 0],
                    [0, 7, 0],
                    [0, 0, 7]], '$x has the right values');
