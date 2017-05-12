#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 122;

use Math::BigNum;

my $x = Math::BigNum->new(42);
my $y = Math::BigNum->new(-42);

my $inf  = Math::BigNum->inf;
my $ninf = Math::BigNum->ninf;
my $nan  = Math::BigNum->nan;

ok($inf->neg == $ninf);
ok($inf == $ninf->neg);
ok($inf + 3 == $inf);
ok(3 + $inf != $ninf);

like("$inf",  qr/^inf/i);
like("$ninf", qr/^-inf/i);

#
## atan(Inf) == pi/2
#
my $pio2 = $inf->atan;
is(ref($pio2), 'Math::BigNum');
like("$pio2", qr/^1\.570/);

my $p = $inf * $ninf;
like("$p", qr/^-inf/i);

$p = $inf * $inf;
like("$p", qr/^inf/i);

$p = $ninf * $ninf;
like("$p", qr/^inf/i);

like("$inf",  qr/^inf/i);
like("$ninf", qr/^-inf/i);

$p = $ninf * $inf;
like("$p", qr/^-inf/i);

###################################################
# operations on Infinity

{
    use Math::BigNum qw(:constant);

    # BigNum
    is(-1 * (-Inf), Inf);
    is(-2 - (-Inf), Inf);
    is(-2 - Inf, -Inf);
    is(2 - (-Inf), Inf);
    is(2 - Inf, -Inf);

    is(-2 + (-Inf), -Inf);
    is(-2 + Inf, Inf);
    is(2 + (-Inf), -Inf);
    is(2 + Inf, Inf);

    is(-2 / (-Inf), 0);
    is(-2 / Inf, 0);    # should be '-0.0'
    is(2 / (-Inf), 0);  # should be '-0.0'
    is(2 / Inf, 0);

    # Scalar
    is("-1" * -Inf, Inf);
    is("-2" - (-Inf), Inf);
    is("-2" - Inf, -Inf);
    is("2" - (-Inf), Inf);
    is("2" - Inf, -Inf);

    is("-2" + (-Inf), -Inf);
    is("-2" + Inf, Inf);
    is("2" + (-Inf), -Inf);
    is("2" + Inf, Inf);

    is("-2" / (-Inf), 0);
    is("-2" / Inf, 0);    # should be '-0.0'
    is("2" / (-Inf), 0);  # should be '-0.0'
    is("2" / Inf, 0);
}

###################################################
# Rational methods
{
    my $one  = Math::BigNum->one;
    my $inf  = Math::BigNum->inf;
    my $ninf = Math::BigNum->ninf;

    my $inum = $inf->numerator;
    my $iden = $inf->denominator;

    is($inum, $inf);
    is($iden, $one);

    is(ref($inum), 'Math::BigNum::Inf');
    is(ref($iden), 'Math::BigNum');

    is($ninf->numerator,   $ninf);
    is($ninf->denominator, $one);

    my ($num, $den) = $ninf->parts;

    is($num, $ninf);
    is($den, $one);

    is(ref($num), 'Math::BigNum::Inf');
    is(ref($den), 'Math::BigNum');

    is($inf->as_rat,  'Inf');
    is($ninf->as_rat, '-Inf');

    is($inf->as_frac,  'Inf/1');
    is($ninf->as_frac, '-Inf/1');
}

###################################################
# Check b* methods

$p = $inf->copy;
$p->badd($ninf);

is(ref($p), 'Math::BigNum::Nan');
is($p,      $nan);

$p = $inf->copy;
$p->bmul(-2);
is($p, $ninf);

$p = $inf->copy;
$p->bmul(0);
is($p, $nan);

$p = $inf->copy;
$p->bmul($y);
is($p, $ninf);

$p = $inf->copy;
$p->bmul(3);
is($p, $inf);

$p = $inf->copy;
$p->bmul($x);
is($p, $inf);

$p = $ninf->copy;
$p->bmul($y);
is($p, $inf);

$p = $ninf->copy;
$p->bmul($ninf);
is($p, $inf);

$p = $ninf->copy;
$p->bmul($inf);
is($p, $ninf);

$p = $inf->copy;
$p->bdiv($x);
is($p, $inf);

$p = $ninf->copy;
$p->bdiv($y);
is($p, $inf);

$p = $ninf->copy;
$p->bdiv($inf);
is($p, $nan);

$p = $ninf->copy;
$p->bidiv($x);
is($p, $ninf);

$p = $ninf->copy;
$p->bsub($y);
is($p, $ninf);

$p = $ninf->copy;
$p->bsub($x);
is($p, $ninf);

$p = $inf->copy;
$p->bsub($x);
is($p, $inf);

$p = $inf->copy;
$p->bsub($y);
is($p, $inf);

$p = $inf->copy;
$p->bsub(34);
is($p, $inf);

$p = $ninf->copy;
$p->bsub(10);
is($p, $ninf);

$p = $ninf->copy;
$p->bsub(-30);
is($p, $ninf);

$p = $x->copy;
$p->bsub($inf);
is($p, $ninf);

$p = $y->copy;
$p->bsub($inf);
is($p, $ninf);

$p = $y->copy;
$p->bmul($ninf);
is($p, $inf);

###################################################
# Infinity <=> Scalar
# Scalar   <=> Infinity

{
    ok($inf > 3);
    ok($inf >= 0);
    ok($ninf < 0);
    ok($ninf <= -1);
    ok($ninf < $inf);
    ok($inf >= $ninf);
    ok($inf > $ninf);
    ok(3 < $inf);
    ok(3 <= $inf);
    ok(3 >= $ninf);
    ok(-2 > $ninf);
    is($inf <=> $inf,  0);
    is($inf <=> $ninf, 1);
    is($ninf <=> $inf, -1);
    is($inf <=> 3,     1);
    is($ninf <=> -3,   -1);
    is($ninf <=> 3,    -1);
    is(3 <=> $inf,     -1);
    is(3 <=> $ninf,    1);
    is(-3 <=> $ninf,   1);
    is(-3 <=> $inf,    -1);
}

###################################################
# Infinity <=> BigNum
# BigNum <=> Infinity

{
    use Math::BigNum qw(:constant);

    ok(Inf > 3);
    ok(Inf >= 0);
    ok(-Inf < 0);
    ok(-Inf <= -1);
    ok(-Inf < Inf);
    ok(Inf >= -Inf);
    ok(Inf > -Inf);
    ok(3 < Inf);
    ok(3 <= Inf);
    ok(3 >= -Inf);
    ok(-2 > -Inf);
    is(Inf <=> Inf,  0);
    is(Inf <=> -Inf, 1);
    is(-Inf <=> Inf, -1);
    is(Inf <=> 3,    1);
    is(-Inf <=> -3,  -1);
    is(-Inf <=> 3,   -1);
    is(3 <=> Inf,    -1);
    is(3 <=> -Inf,   1);
    is(-3 <=> -Inf,  1);
    is(-3 <=> Inf,   -1);
}

# Make sure $x and $y are unchanged
is($x, Math::BigNum->new(42));
is($y, Math::BigNum->new(-42));
