#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Math::LinearApprox;

plan tests => 6;

eval { Math::LinearApprox->new([1]) } or ok($@ =~ /odd number/, "odd number");
eval { Math::LinearApprox->new(1) } or ok($@ =~ /Unknown argument/, "array reference");
eval { Math::LinearApprox::_eq_by_points(0,1,0,1) } or ok($@ =~ /==/, "internal check");
eval { Math::LinearApprox->new()->equation_str() } or ok($@ =~ /Too few/, "too few points");
is_deeply(Math::LinearApprox->new([1, 2])->equation_str(), "x = 1", "only one point");
is_deeply(Math::LinearApprox->new([4, 2, 4, 3, 4, 4])->equation_str(), "x = 4", "vertical line");
