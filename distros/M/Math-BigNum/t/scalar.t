#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 274;

use Math::BigNum;

my $x = Math::BigNum->new(42);

my $zero = Math::BigNum->zero;
my $nan  = Math::BigNum->nan;
my $ninf = Math::BigNum->ninf;
my $inf  = Math::BigNum->inf;

ok($x->is_div(2));
ok($x->is_div(-2));

is($x - $ninf, $inf);
is($x + $ninf, $ninf);

#
## (BigNum, Scalar)
#
is($x - 3, Math::BigNum->new(42 - 3));
is($x + 3, Math::BigNum->new(42 + 3));
is($x * 2, Math::BigNum->new(42 * 2));
is($x / 2, Math::BigNum->new(42 / 2));

is($x * 'inf',  $inf);
is($x * '-inf', $ninf);
is($x / 'inf',  $zero);
is($x / '-inf', $zero);

is($x + 'inf',  $inf);
is($x + '-inf', $ninf);
is($x - 'inf',  $ninf);
is($x - '-inf', $inf);

is($x**'inf',  $inf);
is($x**'-inf', $zero);

is($x->root('inf'),  Math::BigNum->one);
is($x->root('-inf'), Math::BigNum->one);

#
## (Scalar, BigNum)
#
is('inf' * $x,  $inf);
is('-inf' * $x, $ninf);
is('inf' / $x,  $inf);
is('-inf' / $x, $ninf);

is('inf' + $x,  $inf);
is('inf' - $x,  $inf);
is('-inf' + $x, $ninf);
is('-inf' - $x, $ninf);

is('inf'**$x,        $inf);
is('-inf'**$x,       $inf);     # even power
is('-inf'**($x + 1), $ninf);    # odd power

my $max_ui = Math::BigNum->new(Math::BigNum::ULONG_MAX);
my $min_si = Math::BigNum->new(Math::BigNum::LONG_MIN);

my $max_ui_p1 = ($max_ui + 1)->stringify;
my $min_si_m1 = ($min_si - 1)->stringify;

is($min_si_m1 + Math::BigNum->one, $min_si);
is($max_ui_p1 - Math::BigNum->one, $max_ui);
is($max_ui_p1 / ($max_ui + 1), 1);
is($min_si_m1 / ($min_si - 1), 1);
is($min_si - $min_si_m1,              1);
is($max_ui - $max_ui_p1,              -1);
is($max_ui - Math::BigNum::ULONG_MAX, 0);
is($min_si - Math::BigNum::LONG_MIN,  0);
is($max_ui_p1 * Math::BigNum->new(2), ($max_ui + 1) * 2);
is($min_si_m1 * Math::BigNum->new(2), ($min_si - 1) * 2);

is($min_si,                                       Math::BigNum::LONG_MIN);
is(Math::BigNum->new(Math::BigNum::LONG_MIN + 1), Math::BigNum::LONG_MIN + 1);
is($max_ui,                                       Math::BigNum::ULONG_MAX);

is($x->iadd(Math::BigNum::LONG_MIN),              $x + $min_si);
is($x->isub(Math::BigNum::LONG_MIN),              $x - $min_si);
is($x->imul(Math::BigNum::LONG_MIN),              $x * $min_si);
is($min_si->mul(3)->idiv(Math::BigNum::LONG_MIN), 3);

is($x->iadd($max_ui_p1), $x + $max_ui + 1);
is($x->iadd($min_si_m1), $x + $min_si - 1);
is($x->isub($max_ui_p1), $x - $max_ui - 1);
is($x->isub($min_si_m1), $x - $min_si + 1);
is($x->imul($max_ui_p1), $x * ($max_ui + 1));
is($x->imul($min_si_m1), $x * ($min_si - 1));

is($x->iadd(Math::BigNum::ULONG_MAX),              $x + $max_ui);
is($x->isub(Math::BigNum::ULONG_MAX),              $x - $max_ui);
is($x->imul(Math::BigNum::ULONG_MAX),              $x * $max_ui);
is($max_ui->mul(3)->idiv(Math::BigNum::ULONG_MAX), 3);

is($x->mod(Math::BigNum::ULONG_MAX), $x);
is($x->mod(Math::BigNum::LONG_MIN),  $min_si + $x);

is($x->pow(2)->mod(Math::BigNum::ULONG_MAX), 1764);
is($x->pow(2)->mod(Math::BigNum::LONG_MIN),  $min_si + $x**2);

is($max_ui->and(Math::BigNum::ULONG_MAX), Math::BigNum::ULONG_MAX);
is($max_ui->ior(Math::BigNum::ULONG_MAX), Math::BigNum::ULONG_MAX);
is($max_ui->xor(Math::BigNum::ULONG_MAX), 0);

is($max_ui <=> Math::BigNum::ULONG_MAX,    0);
is($max_ui <=> Math::BigNum::ULONG_MAX- 1, 1);
is($min_si <=> Math::BigNum::LONG_MIN,     0);
is($min_si <=> Math::BigNum::LONG_MIN + 1, -1);

is(($min_si + 1)->binomial(Math::BigNum::LONG_MIN), Math::BigNum::LONG_MIN + 1);
is($max_ui->binomial(Math::BigNum::ULONG_MAX- 1),   Math::BigNum::ULONG_MAX);

#
## iadd()
#
{
    my $x = Math::BigNum->new(42);
    $x = $x->iadd(Math::BigNum::ULONG_MAX);
    is($x, 42 + $max_ui);

    $x = Math::BigNum->new(-42);
    $x = $x->iadd($max_ui_p1);
    is($x, -42 + $max_ui + 1);

    $x = Math::BigNum->new(-42);
    $x = $x->iadd(Math::BigNum::LONG_MIN);
    is($x, -42 + $min_si);

    $x = Math::BigNum->new(-42);
    $x = $x->iadd($min_si_m1);
    is($x, -42 + $min_si - 1);

    $x = Math::BigNum->new(42);
    $x = $x->iadd("3.4");
    is($x, 45);
}

#
## biadd()
#
{
    my $x = Math::BigNum->new(42);
    $x->biadd(Math::BigNum::ULONG_MAX);
    is($x, 42 + $max_ui);

    $x = Math::BigNum->new(-42);
    $x->biadd($max_ui_p1);
    is($x, -42 + $max_ui + 1);

    $x = Math::BigNum->new(-42);
    $x->biadd(Math::BigNum::LONG_MIN);
    is($x, -42 + $min_si);

    $x = Math::BigNum->new(42);
    $x->biadd("3.4");
    is($x, 45);
}

#
## isub()
#
{
    my $x = Math::BigNum->new(42);
    $x = $x->isub(Math::BigNum::ULONG_MAX);
    is($x, 42 - $max_ui);

    $x = Math::BigNum->new(-42);
    $x = $x->isub(Math::BigNum::LONG_MIN);
    is($x, -42 - $min_si);

    $x = Math::BigNum->new(-42);
    $x = $x->isub($min_si_m1);
    is($x, -42 - $min_si + 1);

    $x = Math::BigNum->new(-42);
    $x = $x->isub($max_ui_p1);
    is($x, -42 - $max_ui - 1);

    $x = Math::BigNum->new(42);
    $x = $x->isub("3.4");
    is($x, 39);
}

#
## bisub()
#
{
    my $x = Math::BigNum->new(42);
    $x->bisub(Math::BigNum::ULONG_MAX);
    is($x, 42 - $max_ui);

    $x = Math::BigNum->new(-42);
    $x->bisub(Math::BigNum::LONG_MIN);
    is($x, -42 - $min_si);

    $x = Math::BigNum->new(42);
    $x->bisub($min_si_m1);
    is($x, 42 - $min_si + 1);

    $x = Math::BigNum->new(42);
    $x->bisub($max_ui_p1);
    is($x, 42 - $max_ui - 1);

    $x = Math::BigNum->new(42);
    $x->bisub("3.4");
    is($x, 39);
}

#
## imul()
#
{
    my $x = Math::BigNum->new(42);
    $x = $x->imul(Math::BigNum::ULONG_MAX);
    is($x, 42 * $max_ui);

    $x = Math::BigNum->new(-42);
    $x = $x->imul(Math::BigNum::LONG_MIN);
    is($x, -42 * $min_si);

    $x = Math::BigNum->new(2);
    $x = $x->imul(Math::BigNum::LONG_MIN);
    is($x, 2 * $min_si);

    $x = Math::BigNum->new(2);
    $x = $x->imul($max_ui_p1);
    is($x, 2 * ($max_ui + 1));

    $x = Math::BigNum->new(2);
    $x = $x->imul($min_si_m1);
    is($x, 2 * ($min_si - 1));

    $x = Math::BigNum->new(42);
    $x = $x->imul("3.4");
    is($x, 126);
}

#
## bimul()
#
{
    my $x = Math::BigNum->new(42);
    $x->bimul(Math::BigNum::ULONG_MAX);
    is($x, 42 * $max_ui);

    $x = Math::BigNum->new(-42);
    $x->bimul(Math::BigNum::LONG_MIN);
    is($x, -42 * $min_si);

    $x = Math::BigNum->new(2);
    $x->bimul(Math::BigNum::LONG_MIN);
    is($x, 2 * $min_si);

    $x = Math::BigNum->new(2);
    $x->bimul($max_ui_p1);
    is($x, 2 * ($max_ui + 1));

    $x = Math::BigNum->new(2);
    $x->bimul($min_si_m1);
    is($x, 2 * ($min_si - 1));

    $x = Math::BigNum->new(42);
    $x->bimul("3.4");
    is($x, 126);
}

#
## idiv()
#
{
    my $x = $max_ui->mul(3);
    $x = $x->idiv(Math::BigNum::ULONG_MAX);
    is($x, 3);

    $x = ($max_ui + 1)->mul(3);
    $x = $x->idiv($max_ui_p1);
    is($x, 3);

    $x = $min_si->mul(3);
    $x = $x->idiv(Math::BigNum::LONG_MIN);
    is($x, 3);

    $x = ($min_si - 1)->mul(3);
    $x = $x->idiv($min_si_m1);
    is($x, 3);

    $x = Math::BigNum->new(42);
    $x = $x->idiv("3.4");
    is($x, 14);
}

#
## bidiv()
#
{
    my $x = $max_ui->mul(3);
    $x->bidiv(Math::BigNum::ULONG_MAX);
    is($x, 3);

    $x = ($max_ui + 1)->mul(3);
    $x->bidiv($max_ui_p1);
    is($x, 3);

    $x = $min_si->mul(3);
    $x->bidiv(Math::BigNum::LONG_MIN);
    is($x, 3);

    $x = ($min_si - 1)->mul(3);
    $x->bidiv($min_si_m1);
    is($x, 3);

    $x = Math::BigNum->new(42);
    $x->bidiv("3.4");
    is($x, 14);
}

#
## idiv()
#
{
    my $n = Math::BigNum->new(124);
    my $x = $n->copy;
    $x = $x->idiv(-4);
    is($x, -31);

    $x = $n->copy;
    $x = $x->idiv(4);
    is($x, 31);

    $x = $n->neg;
    $x = $x->idiv(-4);
    is($x, 31);

    $x = $n->neg;
    $x = $x->idiv(4);
    is($x, -31);
}

#
## bidiv()
#
{
    my $n = Math::BigNum->new(124);
    my $x = $n->copy;
    $x->bidiv(-4);
    is($x, -31);

    $x = $n->copy;
    $x->bidiv(4);
    is($x, 31);

    $x = $n->neg;
    $x->bidiv(-4);
    is($x, 31);

    $x = $n->neg;
    $x->bidiv(4);
    is($x, -31);
}

#
## badd()
#
{
    my $x = Math::BigNum->new(42);

    is($x->badd(3), Math::BigNum->new(42 + 3));
    is($x,          Math::BigNum->new(42 + 3));

    is($x->badd('inf'), $inf);
    is($x,              $inf);

    my $y = Math::BigNum->new(42);
    is($y->badd('-inf'), $ninf);
    is($y,               $ninf);
}

#
## bsub()
#
{
    my $x = Math::BigNum->new(42);

    is($x->bsub(3), Math::BigNum->new(42 - 3));
    is($x,          Math::BigNum->new(42 - 3));

    is($x->bsub('inf'), $ninf);
    is($x,              $ninf);

    my $y = Math::BigNum->new(42);
    is($y->bsub('-inf'), $inf);
    is($y,               $inf);
}

#
## bmul()
#
{
    my $x = Math::BigNum->new(42);

    is($x->bmul(3), Math::BigNum->new(42 * 3));
    is($x,          Math::BigNum->new(42 * 3));

    is($x->bmul('inf'), $inf);
    is($x,              $inf);

    my $y = Math::BigNum->new(42);
    is($y->bmul('-inf'), $ninf);
    is($y,               $ninf);
}

#
## bdiv()
#
{
    my $x = Math::BigNum->new(42);

    is($x->bdiv(3), Math::BigNum->new(42 / 3));
    is($x,          Math::BigNum->new(42 / 3));

    is($x->bdiv('inf'), $zero);
    is($x,              $zero);

    my $y = Math::BigNum->new(42);
    is($y->bdiv('-inf'), $zero);
    is($y,               $zero);
}

#
## bpow()
#
{
    my $x = Math::BigNum->new(42);

    is($x->bpow(2), Math::BigNum->new(42**2));
    is($x,          Math::BigNum->new(42**2));

    is($x->bpow('inf'), $inf);
    is($x,              $inf);

    my $y = Math::BigNum->new(42);
    is($y->bpow('-inf'), $zero);
    is($y,               $zero);
}

#
## Comparisons
#
ok($x < 'inf');
ok(not $x > 'inf');
ok($x <= 'inf');
ok(not $x >= 'inf');
ok(not $x == 'inf');

ok(not $x < '-inf');
ok($x > '-inf');
ok(not $x <= '-inf');
ok($x >= '-inf');
ok(not $x == '-inf');

ok($inf == 'inf');
ok('inf' == $inf);
ok($inf != '-inf');
ok('-inf' != $inf);
ok($ninf == '-inf');
ok('-inf' == $ninf);

ok(not $inf == '-inf');
ok(not '-inf' == $inf);
ok(not $ninf != '-inf');
ok(not '-inf' != $ninf);

is($x <=> 'inf',  -1);
is($x <=> '-inf', 1);

ok(not $inf < 'inf');
is($inf <=> 'inf',      0);
is($inf->acmp('inf'),   0);
is($ninf->acmp('inf'),  0);
is($ninf->acmp('-inf'), 0);
is($inf->acmp('-inf'),  0);
is($inf->acmp(42),      1);
is($ninf->acmp(42),     1);

ok($x == 42);
ok(42 == $x);

ok($inf == 'inf');
ok($ninf == '-inf');
ok('-inf' == $ninf);
ok(not 'inf' == $ninf);
ok(not $ninf == 'inf');
ok(not $x == 'inf');

ok($x != 'inf');
ok(not $x != 42);
ok('-inf' != $x);
ok($inf != '-inf');
ok(not 'inf' != $inf);
ok(not $ninf != '-inf');

ok($x < 'inf');
ok('-inf' < $x);
ok(not $x < '-inf');
ok(not 'inf' < $x);

ok($x > '-inf');
ok('inf' > $x);
ok(not $x > 'inf');
ok(not '-inf' > $x);

ok('-inf' <= $x);
ok($x <= 'inf');
ok(not $x <= '-inf');
ok(not 'inf' <= $x);

ok($x >= '-inf');
ok('inf' >= $x);
ok(not $x >= 'inf');
ok(not '-inf' >= $x);

is($x->log(4)->int, 2);
is($x->log('inf'),  0);
is($x->log('NaN'),  $nan);

# is_div()
{
    is($max_ui->is_div(Math::BigNum::ULONG_MAX),           1);
    is($max_ui->is_div(Math::BigNum::ULONG_MAX- 1),        0);
    is(($max_ui->dec)->is_div(Math::BigNum::ULONG_MAX- 1), 1);

    is(($max_ui->inc)->is_div($max_ui_p1), 1);
    is(($min_si->dec)->is_div($min_si_m1), 1);

    is($max_ui->is_div($max_ui_p1), 0);
    is($min_si->is_div($min_si_m1), 0);

    is($x->is_div(2),                             1);
    is(Math::BigNum->new("218.4")->is_div("5.2"), 1);
    is(Math::BigNum->new("218.4")->is_div("6.2"), 0);
}

# hypot()
{
    like($x->hypot(123.4), qr/^130\.3516/);
    like($x->hypot(321),   qr/^323\.7360/);
    like($x->hypot(-321),  qr/^323\.7360/);

    is($x->hypot('-inf'), $inf);
    is($x->hypot('inf'),  $inf);
    is($x->hypot('abc'),  $nan);
}

# blog()
{
    my $n = Math::BigNum->new(42);
    my $x = $n->copy;
    $x->blog(4)->bint;
    is($x, 2);

    $x = $n->copy;
    $x->blog('Inf');
    is($x, 0);

    $x = $n->copy;
    $x->blog('NaN');
    is($x, $nan);

    $x = $n->copy;
    $x->blog('abc');
    is($x, $nan);
}

# atan2()
{
    like(atan2(1,     $zero), qr/^1\.57079/);
    like(atan2(-1,    $zero), qr/^-1\.57079/);
    like(atan2($zero, -1),    qr/^3\.14159/);
    like(atan2($x,    42),    qr/^0\.78539/);

    is(atan2($x,    'abc'), $nan);
    is(atan2('abc', $x),    $nan);

    like(atan2($zero, '-Inf'), qr/^3\.14159/);
    like(atan2('Inf', $zero),  qr/^1\.57079/);
}

# mod()
{
    like($x->mod("12.4"), qr/^4\.[78]/);
    is($x->mod('inf'),  $x);
    is($x->mod('abc'),  $nan);
    is($x->mod('-inf'), $ninf);
}

# bmod()
{
    my $n = Math::BigNum->new(42);
    my $x = $n->copy;

    $x->bmod("12.4");
    like($x, qr/^4\.[78]/);

    $x = $n->copy->bmod('inf');
    is($x, $n);

    $x = $n->copy->bmod('abc');
    is($x, $nan);

    $x = $n->copy->bmod('-Inf');
    is($x, $ninf);
}

#
## NaN
#

is($x + 'nan',    $nan);
is('nan' - $x,    $nan);
is('NaN' / $x,    $nan);
is($x / 'NaN',    $nan);
is($x * 'NaN',    $nan);
is('NaN' / $x,    $nan);
is('nan' * $inf,  $nan);
is('nan' / $inf,  $nan);
is($ninf / 'nan', $nan);
is('nan' + $nan,  $nan);
is('nan'**$inf,   $nan);
is($inf**'nan',   $nan);
is($ninf**'nan',  $nan);

#
## This is, somewhat, undefined behavior, so please don't rely on it!
#

is(Math::BigNum->new('abc'), $nan);

is($x + 'abc', $nan);
is('abc' + $x, $nan);
is('abc' - $x, $nan);
is('abc' * $x, $nan);
is($x * 'abc', $nan);
is($x / 'abc', $nan);
is('abc' / $x, $nan);
is('abc'**$x,  $nan);
is($x**'abc',  $nan);

is($x->log('abc'), $nan);

# Final test to make sure $x didn't change
is($x, 42);
