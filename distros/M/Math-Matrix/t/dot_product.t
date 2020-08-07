#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 4;

my $xd = [1, 2, 3];
my $yd = [4, 5, 6];

my $x = Math::Matrix -> new($xd);
my $y = Math::Matrix -> new($yd);

# Test dot_product() with object argument.

my $p = $x -> dot_product($y);

is(ref($p), '', '$p is a scalar');
cmp_ok($p, '==', 32, '$p has the right value');

# Test dot_product() with array argument.

my $q = $x -> dot_product($yd);

is(ref($q), '', '$q is a scalar');
cmp_ok($q, '==', 32, '$q has the right value');
