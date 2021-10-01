# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

plan tests => 179;

use Math::BigFloat::Constant;

my $x = Math::BigFloat::Constant->new(8);

###########################################################################
# allowed operations

is(ref $x, 'Math::BigFloat::Constant', 'ref');

_is($x, $x, 8, 'bstr');
_is($x, $x+2, 10, ' copy add works');
_is($x, $x->bsstr(), '8e+0', 'bsstr');

#_is($x, $x->bfloor(), 8, 'floor');
#_is($x, $x->bceil(), 8, 'ceil');

#_is($x, $x->as_int(), 8, 'as_int');
#_is($x, $x->as_number(), 8, 'as_number');

_is($x, $x->is_pos(), 1, 'is_pos');
_is($x, $x->is_int(), 1, 'is_int');

_is($x, $x->is_neg(), 0, 'is_neg');
_is($x, $x->is_one() || 0, 0, 'is_one');
_is($x, $x->is_nan(), 0, 'is_nan');
_is($x, $x->is_inf(), 0, 'is_inf');
_is($x, $x->is_zero() || 0, 0, 'is_zero');

_is($x, $x->bstr(), '8', 'bstr');
_is($x, $x->bsstr(), '8e+0', 'bsstr');
#_is($x, $x->digit(0), '8', 'digit');

_is($x, $x->as_hex(), '0x8', 'as_hex');
_is($x, $x->as_bin(), '0b1000', 'as_bin');
_is($x, $x->as_oct(), '010', 'as_oct');

#is($x = Math::BigFloat::Constant -> from_hex("8"),      '8', 'from_hex');
#is($x = Math::BigFloat::Constant -> from_oct("10"),     '8', 'from_oct');
#is($x = Math::BigFloat::Constant -> from_bin("1000"),   '8', 'from_bin');
#is($x = Math::BigFloat::Constant -> from_bytes("\x08"), '8', 'from_bytes');

my $y = Math::BigFloat::Constant->new(32);
is($x->bgcd($y), 8, 'gcd');
$y = Math::BigFloat::Constant->new(53);
my $z = Math::BigFloat::Constant->new(19);
is($x->blcm($y, $z), 19*53*8, 'lcm');

###########################################################################
# disallowed operation

# unary operations

foreach my $method (qw/
               bfloor bceil as_int as_number
               binc bdec bfac bnot bneg babs
               bzero bone binf bnan
           /)
{
    is(ref $x, 'Math::BigFloat::Constant', 'ref x still ok');
    $@ = '';
    my $test = "\$x->$method();";
    my $out  = eval $test;
    is($x, 8, 'x is 8') or diag($test);
    is($out, undef, 'undef');
    like($@, qr/^Can not.*$method/, "$method died");
}

# binary operations

foreach my $method (qw/
               badd bsub bmul bdiv bmod
               bxor bior band bpow blsft brsft
               broot bsqrt bexp bnok blog
               bfround bround
               from_bin from_oct from_hex
           /)
{
    is(ref $x, 'Math::BigFloat::Constant', 'ref x still ok');
    $@ = '';
    my $test = "\$x->$method(1);";
    my $out  = eval $test;
    is($x, 8, 'x is 8') or diag($test);
    is($out, undef, 'undef');
    like($@, qr/^Can not.*$method/, "$method died");
}

# ternary operations

foreach my $method (qw/
               bmodpow bmodinv
           /)
{
    $@ = '';
    my $test = "\$x->$method(2, 3);";
    my $out  = eval $test;
    is($x, 8, 'x is 8') or diag($test);
    is($out, undef, 'undef');
    like($@, qr/^Can not.*$method/, "$method died");
}

###########################################################################

sub _is {
    my ($x, $a, $b, $c) = @_;

    is($a, $b, $c);
    is(ref $x, 'Math::BigFloat::Constant', 'ref');
}

1;
