# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

plan tests => 247;

use Math::BigRat::Constant;

my $class = 'Math::BigRat::Constant';

my $x = $class->new(8);

###########################################################################
# allowed operations

is(ref $x, $class, 'ref');

_is($x, $x, 8, 'bstr');
_is($x, $x+2, 10, ' copy add works');
_is($x, $x->bsstr(), '8', 'bsstr');

_is($x, $x->as_int(), 8, 'as_int');
_is($x, $x->as_number(), 8, 'as_number');

_is($x, $x->is_even(),         1, 'is_even');
_is($x, $x->is_finite(),       1, 'is_finite');
_is($x, $x->is_inf(),          0, 'is_inf');
_is($x, $x->is_int(),          1, 'is_int');
_is($x, $x->is_nan(),          0, 'is_nan');
_is($x, $x->is_negative(),     0, 'is_negative');
_is($x, $x->is_non_negative(), 1, 'is_non_negative');
_is($x, $x->is_non_positive(), 0, 'is_non_positive');
_is($x, $x->is_odd(),          0, 'is_odd');
_is($x, $x->is_one(),          0, 'is_one');
_is($x, $x->is_positive(),     1, 'is_positive');
_is($x, $x->is_zero(),         0, 'is_zero');

_is($x, $x->bstr(),   '8',    'bstr');
_is($x, $x->bsstr(),  '8',    'bsstr');
#_is($x, $x->bdstr(),  '8',    'bdstr');
#_is($x, $x->bestr(),  '8e+0', 'bestr');
_is($x, $x->bfstr(),  '8',    'bfstr');
#_is($x, $x->bnstr(),  '8e+0', 'bnstr');

#_is($x, $x->digit(0), '8', 'digit');    # no Math::BigRat->digit()

_is($x, $x->as_hex(), '0x8',    'as_hex');
_is($x, $x->as_bin(), '0b1000', 'as_bin');
_is($x, $x->as_oct(), '010',    'as_oct');

_is($x, $x->as_int(),   8, 'as_int');
_is($x, $x->as_float(), 8, 'as_float');
_is($x, $x->as_rat(),   8, 'as_rat');

_is($x, $x->to_base(10),     8, 'to_base');
_is($x, $x->to_bin(),     1000, 'to_bin');
#_is($x, $x->to_bytes(), "\x08", 'to_bytes');    # no Math::BigRat->to_bytes()
_is($x, $x->to_hex(),        8, 'to_hex');
_is($x, $x->to_oct(),       10, 'to_oct');

_is($x, $x->numerator(),   8, 'numerator');
_is($x, $x->denominator(), 1, 'denominator');

is($x = $class -> from_hex("8"),      '8', 'from_hex');
is($x = $class -> from_oct("10"),     '8', 'from_oct');
is($x = $class -> from_bin("1000"),   '8', 'from_bin');
#is($x = $class -> from_bytes("\x08"), '8', 'from_bytes'); # no Math::BigRat->to_bytes()

my $y = $class->new(32);
is($x->bgcd($y), 8, 'gcd');
$y = $class->new(53);
my $z = $class->new(19);
is($x->blcm($y, $z), 19*53*8, 'lcm');

###########################################################################
# disallowed operation

# unary operations

for my $method (qw/
                      bzero bone binf bnan
                      binc bdec babs bneg binv bsgn bdigitsum
                      bceil bfloor bint
                      bclog2 bclog10 bilog2 bilog10
                      bfac bdfac btfac
                      bfib blucas bnot
                      bsin bcos batan
                  /)
{
    my ($x, $y, $test);
    $test = "\$x = $class -> new(8);";
    $test .= " \$y = \$x -> $method();";
    note("\n$test\n\n");
    $@ = '';
    eval $test;
    is($x, 8, '$x is 8');
    is($y, undef, '$y is undef');
    like($@, qr/^Can not.*$method/, "$method died, as expected");
}

# binary operations

for my $method (qw/
                      badd bsub bmul bfdiv bfmod btdiv btmod
                      bxor bior band
                      blsft brsft bblsft bbrsft
                      bpow broot bsqrt bexp bnok blog
                      bfround bround round
                      from_dec from_bin from_oct from_hex
                  /)
{
    my ($x, $y, $test);
    $test = "\$x = $class -> new(8);";
    $test .= " \$y = \$x -> $method(1);";
    note("\n$test\n\n");
    $@ = '';
    eval $test;
    is($x, 8, '$x is 8');
    is($y, undef, '$y is undef');
    like($@, qr/^Can not.*$method/, "$method died, as expected");
}

# ternary operations

for my $method (qw/
                      bmodpow bmodinv bmuladd
                      bhyperop buparrow
                  /)
{
    my ($x, $y, $test);
    $test = "\$x = $class -> new(8);";
    $test .= " \$y = \$x -> $method(1, 2);";
    note("\n$test\n\n");
    $@ = '';
    eval $test;
    is($x, 8, '$x is 8');
    is($y, undef, '$y is undef');
    like($@, qr/^Can not.*$method/, "$method died, as expected");
}

###########################################################################

sub _is {
    my ($x, $a, $b, $c) = @_;

    is($a, $b, $c);
    is(ref($x), $class, "\$x is a $class");
}
