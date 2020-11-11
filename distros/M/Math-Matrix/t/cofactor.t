#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 10;

my ($x, $y);
$x = Math::Matrix -> new([[ 3, -1,  5 ],
                          [ 4,  0,  2 ],
                          [ 2,  6, -5 ]]);

$y = $x -> cofactor(0, 0);
cmp_ok($y, '==', -12, 'cofactor(0, 0)');

$y = $x -> cofactor(0, 1);
cmp_ok($y, '==',  24, 'cofactor(0, 1)');

$y = $x -> cofactor(0, 2);
cmp_ok($y, '==',  24, 'cofactor(0, 2)');

$y = $x -> cofactor(1, 0);
cmp_ok($y, '==',  25, 'cofactor(1, 0)');

$y = $x -> cofactor(1, 1);
cmp_ok($y, '==', -25, 'cofactor(1, 1)');

$y = $x -> cofactor(1, 2);
cmp_ok($y, '==', -20, 'cofactor(1, 2)');

$y = $x -> cofactor(2, 0);
cmp_ok($y, '==',  -2, 'cofactor(2, 0)');

$y = $x -> cofactor(2, 1);
cmp_ok($y, '==',  14, 'cofactor(2, 1)');

$y = $x -> cofactor(2, 2);
cmp_ok($y, '==',   4, 'cofactor(2, 2)');

# Verify that $x is unmodified.

is_deeply([ @$x ], [[ 3, -1,  5 ],
                    [ 4,  0,  2 ],
                    [ 2,  6, -5 ]], '$x is unmodified');
