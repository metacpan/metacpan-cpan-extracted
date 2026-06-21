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

{
    use Infix::Custom op => '⊞', binop => '+', prec => 'add';
    is(2 ⊞ 3, 5, 'operator active after use');

    no Infix::Custom '⊞';

    # After `no`, the hint is gone at this point of compilation; a fresh compile
    # of the glyph (string eval inherits these hints) is a parse error.
    my $r = eval q{ 2 ⊞ 3 };
    ok(!defined $r, 'operator removed by "no Infix::Custom GLYPH"');
    like($@, qr/\S/, 'using the removed operator is a compile error');
}
