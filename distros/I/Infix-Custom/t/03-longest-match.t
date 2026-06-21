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

plan tests => 3;

# Two operators where one glyph is a prefix of the other. The dispatcher must
# claim the longest matching glyph, so `a ⊕⊕ b` is NOT parsed as `a ⊕ (⊕b)`.
use Infix::Custom op => '⊕',  call => \&add, prec => 'add';
use Infix::Custom op => '⊕⊕', call => \&sub_, prec => 'add';

sub add  { $_[0] + $_[1] }
sub sub_ { $_[0] - $_[1] }

is(5 ⊕ 3,  8, 'single-glyph operator resolves to its own definition');
is(5 ⊕⊕ 3, 2, 'longest match wins: the 2-glyph op is not glyph-then-glyph');
is(1 ⊕ 5 ⊕⊕ 2, 4, 'mixed single/double glyph, both groupings == 4');
