#!perl

use strict;
use warnings;

use lib 't/lib';
use Math::Matrix::Real;

use Test::More tests => 3;

# 1-by-1 matrix

my $x1 = Math::Matrix::Real -> new([3]);

my $d1 = $x1 -> determinant();
cmp_ok($d1, '==', 3, '$d1 has the right value');

# 2-by-2 matrix

my $x2 = Math::Matrix::Real -> new([1, 3],
                                   [5, 4]);

my $d2 = $x2 -> determinant();
cmp_ok($d2, '==', -11, '$d2 has the right value');

# 3-by-3 matrix

my $x3 = Math::Matrix::Real -> new([3, 1, 2],
                                   [4, 9, 7],
                                   [5, 0, 8]);

my $d3 = $x3 -> determinant();
cmp_ok($d3, '==', 129, '$d3 has the right value');
