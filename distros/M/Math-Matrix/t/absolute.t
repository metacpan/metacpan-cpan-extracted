#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 6;

my $x = Math::Matrix -> new([[1, 0, 2, 0, 2]]) -> absolute();
is(ref($x), '', '$x is a scalar');
cmp_ok($x, '==', 3, '$x has the right value');

my $y = Math::Matrix -> new([[3, 4]]) -> absolute();
is(ref($y), '', '$y is a scalar');
cmp_ok($y, '==', 5, '$y has the right value');

my $z = Math::Matrix -> new([[9, 40]]) -> absolute();
is(ref($z), '', '$z is a scalar');
cmp_ok($z, '==', 41, '$z has the right value');
