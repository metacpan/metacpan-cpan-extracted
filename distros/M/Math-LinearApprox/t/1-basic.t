#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Math::LinearApprox qw( linear_approx linear_approx_str );

plan tests => 2;

my @points = ( 
        0, 4,
        2, 1,
        7, -6.5,
        );

is_deeply([linear_approx(\@points)], [-1.5, 4], "coefficents approximation");
is_deeply(linear_approx_str(\@points), "y = -1.5 * x + 4", "string approximation");
