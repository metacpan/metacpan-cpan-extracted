#!perl
use 5.014;
use strict;
use warnings;
use utf8;
use Test::More;

# Custom operators only exist on 5.38+, where PL_infix_plugin lives.
BEGIN {
    plan skip_all => "custom infix operators require perl 5.38+ (have $])"
        unless "$]" >= 5.038;
}

plan tests => 5;

use_ok('Infix::Custom');

# Declared at compile time; active for the rest of this file's lexical scope,
# so the operators below are used literally (no string eval needed).
use Infix::Custom op => '⊕', call => \&add, prec => 'add';
use Infix::Custom '⊗' => \&mul,             prec => 'mul';   # shorthand

sub add { $_[0] + $_[1] }
sub mul { $_[0] * $_[1] }

is(2 ⊕ 3, 5, 'call mode: 2 (+) 3 == 5');
is(2 ⊗ 3, 6, 'shorthand declaration + call mode: 2 (x) 3 == 6');

# (+) binds like '+'; either grouping of `1 + 2 (+) 3` yields 6.
is(1 + 2 ⊕ 3, 6, 'add-precedence operator: 1 + 2 (+) 3 == 6');

# (x) is mul-prec (tighter): 1 (+) (2 (x) 3) = add(1, 6) = 7.
is(1 ⊕ 2 ⊗ 3, 7, 'mul-prec operator binds tighter than add-prec operator');
