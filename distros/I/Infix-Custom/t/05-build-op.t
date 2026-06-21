#!perl
use 5.014;
use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
    plan skip_all => "custom infix operators require perl 5.38+ (have $])"
        unless "$]" >= 5.038;
}

plan tests => 2;

# The build_op escape hatch: register an operator whose optree is built by a
# C function supplied as a pointer (here a test helper that lowers to native
# subtraction, so the result is distinct from any call/binop mode).
my $build_op = Infix::Custom::_sample_build_op();
ok($build_op, 'got a non-null build_op pointer from the test helper');

use Infix::Custom op => '⊟', build_op => Infix::Custom::_sample_build_op(),
                  prec => 'add';

is(10 ⊟ 3, 7, 'build_op escape hatch lowers via the supplied C function');
