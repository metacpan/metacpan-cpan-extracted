#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 10;

my ($x, $y);

$x = Math::Matrix -> new([[ 3, -1,  5 ],
                          [ 4,  0,  2 ],
                          [ 2,  6, -5 ]]);

$y = $x -> minor(0, 0);
cmp_ok($y, '==', -12, '$x -> minor(0, 0)');

$y = $x -> minor(0, 1);
cmp_ok($y, '==', -24, '$x -> minor(0, 1)');

$y = $x -> minor(0, 2);
cmp_ok($y, '==', 24, '$x -> minor(0, 2)');

$y = $x -> minor(1, 0);
cmp_ok($y, '==', -25, '$x -> minor(1, 0)');

$y = $x -> minor(1, 1);
cmp_ok($y, '==', -25, '$x -> minor(1, 1)');

$y = $x -> minor(1, 2);
cmp_ok($y, '==', 20, '$x -> minor(1, 2)');

$y = $x -> minor(2, 0);
cmp_ok($y, '==', -2, '$x -> minor(2, 0)');

$y = $x -> minor(2, 1);
cmp_ok($y, '==', -14, '$x -> minor(2, 1)');

$y = $x -> minor(2, 2);
cmp_ok($y, '==', 4, '$x -> minor(2, 2)');

# Verify that $x is not modified.

is_deeply([ @$x ], [[ 3, -1,  5 ],
                    [ 4,  0,  2 ],
                    [ 2,  6, -5 ]], '$x is unmodified');
