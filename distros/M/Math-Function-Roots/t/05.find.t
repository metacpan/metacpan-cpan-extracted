#!perl -T

use warnings;
use strict;

use Test::More tests => 1;

use lib 'lib';
use Math::Function::Roots qw(find epsilon);

epsilon(0);
is( find( sub{ -1*shift() + 2 } ), 2, "find: exact result");

# write other tests giving range.