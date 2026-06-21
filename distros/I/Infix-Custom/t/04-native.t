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

plan tests => 4;

# Op mode: the operator lowers straight to a native binary op, no sub call.
use Infix::Custom op => '⊕', binop => '+', prec => 'add';
use Infix::Custom op => '⊙', binop => '*', prec => 'mul';
use Infix::Custom op => '⋅', binop => '.', prec => 'add';

is(2 ⊕ 3, 5, 'native binop +: 2 (+) 3 == 5');
is(4 ⊙ 5, 20, 'native binop *: 4 (*) 5 == 20');
is('a' ⋅ 'b', 'ab', 'native binop . (concat)');

# precedence still honoured: (*) tighter than (+)
is(2 ⊕ 3 ⊙ 4, 14, 'native ops respect precedence: 2 + 3 * 4 == 14');
