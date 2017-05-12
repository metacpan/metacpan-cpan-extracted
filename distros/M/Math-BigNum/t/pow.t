#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 360;

use Math::BigNum;

my $int1 = Math::BigNum->new(3);
my $int2 = Math::BigNum->new(-4);

#################################################################
# integer

my $r = $int1**$int1;
is("$r", "27");

$r = $int1->ipow($int1);
is("$r", "27");

$r = $int1**4;
is("$r", "81");

$r = $int1->ipow(4);
is("$r", "81");

$r = 4**$int1;
is("$r", "64");

$r = $int2**$int1;
is("$r", "-64");

$r = $int2**2;
is("$r", "16");

$r = $int1**$int2;
ok($r == 1 / ($int1**abs($int2)));

$r = $int1->ipow($int2);
is("$r", "0");

$r = $int2->ipow($int1);
is("$r", "-64");

$r = $int2->ipow(2);
is("$r", "16");

$r = (-$int1)**($int2);
ok($r == 1 / ($int1**abs($int2)));

$r = (-$int1)**($int2 - 1);
ok($r == -(1 / ($int1**abs($int2 - 1))));

$r = $int2**(-$int1);
is("$r", "-0.015625");

$r = $int2**(-$int1 + 1);
is("$r", "0.0625");

#################################################################
# float + int

my $float1 = Math::BigNum->new(3.45);
my $float2 = Math::BigNum->new(-5.67);

$r = $float1**$int1;
is("$r", "41.063625");

$r = $float1**$int2;
like("$r", qr/^0\.00705868/);

$r = $float1**$float2;
like("$r", qr/^0\.0008924/);

$r = $float2**$int1;
is("$r", "-182.284263");

$r = $float2**$int2;
like("$r", qr/^0\.00096753/);

$r = $float2**abs($int2);
is("$r", "1033.55177121");

$r = $float1**4;
is("$r", "141.66950625");

$r = $float2**2;
is("$r", "32.1489");

$r = $float2**3;
is("$r", "-182.284263");

$r = $float1**2.34;
like("$r", qr/^18\.13412823/);

#$r = $float2**2.25;
#is(ref($r), 'Math::BigNum::Complex');
#like("$r", qr/^35\.078974175.*?\+35\.078974175.*?i\z/);

$r = 3**$float1;
like("$r", qr/^44\.2658011/);

$r = 1.23**$float2;
like("$r", qr/^0\.309198955/);

$r = 0**$float2;
is(ref($r),  'Math::BigNum::Inf');
is(lc("$r"), 'inf');

$r = Math::BigNum->new(0)**$int2;
is(ref($r),  'Math::BigNum::Inf');
is(lc("$r"), 'inf');

$r = Math::BigNum->new(0)**$int1;
is("$r", "0");

$r = 0**($int2 - 1);
is(lc("$r"), 'inf');

#################################################################
# bpow() -- int

$r = $int1->copy;
$r->bpow($int1);
is("$r", "27");

$r = $int1->copy;
$r->bipow($int1);
is("$r", "27");

$r = $int1->copy;
$r->bpow(4);
is("$r", "81");

$r = $int1->copy;
$r->bipow(4);
is("$r", "81");

$r = $int1->copy;
$r->bpow($int2);
ok($r == 1 / ($int1**abs($int2)));

$r = $int1->copy;
$r->bipow($int2);
is("$r", "0");

$r = (-$int1)->copy;
$r->bpow($int2);
ok($r == 1 / ($int1**abs($int2)));

$r = (-$int1)->copy;
$r->bpow($int2 - 1);
ok($r == -(1 / ($int1**abs($int2 - 1))));

$r = $int2->copy;
$r->bpow(-$int1);
is("$r", "-0.015625");

$r = $int2->copy;
$r->bpow(-$int1 + 1);
is("$r", "0.0625");

#################################################################
# bpow() -- float + int

$r = $float1->copy;
$r->bpow($int1);
is("$r", "41.063625");

$r = $float1->copy;
$r->bpow($int2);
like("$r", qr/^0\.00705868/);

$r = $float1->copy;
$r->bpow($float2);
like("$r", qr/^0\.0008924/);

$r = $float2->copy;
$r->bpow($int1);
is("$r", "-182.284263");

$r = $float2->copy;
$r->bpow($int2);
like("$r", qr/^0\.00096753/);

$r = $float2->copy;
$r->bpow(abs($int2));
is("$r", "1033.55177121");

$r = $float1->copy;
$r->bpow(4);
is("$r", "141.66950625");

$r = $float2->copy;
$r->bpow(2);
is("$r", "32.1489");

$r = $float2->copy;
$r->bpow(3);
is("$r", "-182.284263");

$r = $float1->copy;
$r->bpow(2.34);
like("$r", qr/^18\.13412823/);

#$r = $float2->copy;
#$r->bpow(2.25);
#is(ref($r), 'Math::BigNum::Complex');
#like("$r", qr/^35\.078974175.*?\+35\.078974175.*?i\z/);

$r = Math::BigNum->new(0);
$r->bpow(-2);
is(ref($r),  'Math::BigNum::Inf');
is(lc("$r"), "inf");

{
    my $n = Math::BigNum->new('12.6');
    $n->bfpow('3.45');
    like("$n", qr/^6255\.735538995494576076354865979491381\d*\z/);
}

{
    my $n = Math::BigNum->new('12.6');
    $n->bpow('3.45');
    like("$n", qr/^6255\.735538995494576076354865979491381\d*\z/);
}

{
    my $n = Math::BigNum->new('12.6');
    $n->bipow('3.45');
    is("$n", "1728");
}

##############################################################
# special values
# See: https://en.wikipedia.org/wiki/NaN#Operations_generating_NaN

{
    use Math::BigNum qw(:constant);

    # BigNum
    is(0**0,               1);
    is(0**Inf,             0);
    is(0**(-Inf),          Inf);
    is(ref(0**0),          'Math::BigNum');    # make sure we're getting BigNum objects
    is(1**Inf,             1);
    is((-1)**Inf,          1);
    is(1**(-Inf),          1);
    is((-1)**(-Inf),       1);
    is(Inf**0,             1);
    is((-Inf)**0,          1);
    is((-Inf)**2,          Inf);
    is((-Inf)**3,          -Inf);
    is((-Inf)**2.3,        Inf);               # shouldn't be NaN?
    is(Inf**2.3,           Inf);
    is(Inf**-2.3,          0);
    is((-Inf)**-3,         0);
    is(Inf**Inf,           Inf);
    is((-Inf)**Inf,        Inf);
    is((-Inf)**(-Inf),     0);
    is(Inf**(-Inf),        0);
    is(100**(-Inf),        0);
    is((-100)**(-Inf),     0);
    is(((0**(1 / 0))**0),  1);
    is(0->root(0)->pow(0), 1);
    is((Inf)**(1 / (-12)), 0);
    is((-Inf)**(1 / (-12)), 0);
    is((Inf)**(1 / (2)), Inf);
    is((-Inf)**(1 / (2)), Inf);    # sqrt(-Inf) -- shouldn't be NaN?
    is((Inf)**(1 / (Inf)), 1);
    is((-Inf)**(1 / (Inf)), 1);
    is((Inf)**(1 / (-Inf)), 1);
    is((-Inf)**(1 / (-Inf)), 1);

    # Scalar
    is("1"**Inf,               1);
    is("-1"**Inf,              1);
    is("1"**(-Inf),            1);
    is("-1"**(-Inf),           1);
    is(Inf**"0",               1);
    is((-Inf)**"0",            1);
    is((-Inf)**"2",            Inf);
    is((-Inf)**"3",            -Inf);
    is((-Inf)**"2.3",          Inf);    # shouldn't be NaN?
    is(Inf**"2.3",             Inf);
    is(Inf**"-2.3",            0);
    is((-Inf)**"-3",           0);
    is("100"**(-Inf),          0);
    is("-100"**(-Inf),         0);
    is(((0**(1 / 0))**"0"),    1);
    is((("0"**(1 / 0))**"0"),  1);
    is(0->root("0")->pow("0"), 1);
    is((Inf)**("1" / (Inf)), 1);
    is((-Inf)**("1" / (Inf)), 1);
    is((Inf)**("1" / (-Inf)), 1);
    is((-Inf)**("1" / (-Inf)), 1);
}

# bpow()

{
    use Math::BigNum qw(:constant);

    # BigNum
    is(0->copy->bpow(0),                        1);
    is(0->copy->bpow(Inf),                      0);
    is(0->copy->bpow(-Inf),                     Inf);
    is(ref(0->copy->bpow(0)),                   'Math::BigNum');    # make sure we're getting BigNum objects
    is(1->copy->bpow(Inf),                      1);
    is((-1)->copy->bpow(Inf),                   1);
    is(1->copy->bpow(-Inf),                     1);
    is((-1)->copy->bpow(-Inf),                  1);
    is(Inf->copy->bpow(0),                      1);
    is((-Inf)->copy->bpow(0),                   1);
    is((-Inf)->copy->bpow(2),                   Inf);
    is((-Inf)->copy->bpow(3),                   -Inf);
    is((-Inf)->copy->bpow(2.3),                 Inf);               # shouldn't be NaN?
    is(Inf->copy->bpow(2.3),                    Inf);
    is(Inf->copy->bpow(-2.3),                   0);
    is((-Inf)->copy->bpow(-3),                  0);
    is(Inf->copy->bpow(Inf),                    Inf);
    is((-Inf)->copy->bpow(Inf),                 Inf);
    is((-Inf)->copy->bpow(-Inf),                0);
    is(Inf->copy->bpow(-Inf),                   0);
    is(100->copy->bpow(-Inf),                   0);
    is((-100)->copy->bpow(-Inf),                0);
    is(((0->copy->bpow(1 / 0))->copy->bpow(0)), 1);
    is(0->copy->broot(0)->bpow(0),              1);
    is((Inf)->copy->bpow(1 / (-12)), 0);
    is((-Inf)->copy->bpow(1 / (-12)), 0);
    is((Inf)->copy->bpow(1 / (2)), Inf);
    is((-Inf)->copy->bpow(1 / (2)), Inf);    # sqrt(-Inf) -- shouldn't be NaN?
    is((Inf)->copy->bpow(1 / (Inf)), 1);
    is((-Inf)->copy->bpow(1 / (Inf)), 1);
    is((Inf)->copy->bpow(1 / (-Inf)), 1);
    is((-Inf)->copy->bpow(1 / (-Inf)), 1);

    # Scalar
    is(Inf->copy->bpow("0"),                      1);
    is((-Inf)->copy->bpow("0"),                   1);
    is((-Inf)->copy->bpow("2"),                   Inf);
    is((-Inf)->copy->bpow("3"),                   -Inf);
    is((-Inf)->copy->bpow("2.3"),                 Inf);    # shouldn't be NaN?
    is(Inf->copy->bpow("2.3"),                    Inf);
    is(Inf->copy->bpow("-2.3"),                   0);
    is((-Inf)->copy->bpow("-3"),                  0);
    is(((0->copy->bpow(1 / 0))->copy->bpow("0")), 1);
    is(0->copy->broot("0")->bpow("0"),            1);
    is((Inf)->copy->bpow("1" / (Inf)), 1);
    is((-Inf)->copy->bpow("1" / (Inf)), 1);
    is((Inf)->copy->bpow("1" / (-Inf)), 1);
    is((-Inf)->copy->bpow("1" / (-Inf)), 1);
}

{
    my $mone = Math::BigNum->new(-1);
    my $one  = Math::BigNum->new(1);
    my $zero = Math::BigNum->new(0);

    my $inf  = Math::BigNum->inf;
    my $ninf = Math::BigNum->ninf;

    # NEGATIVE INFINITY
    is($ninf**$inf,  $inf);
    is($ninf**$ninf, $zero);
    is($ninf**$zero, $one);
    is($ninf**$one,  $ninf);
    is($ninf**$mone, $zero);    # actually -0.0

    is($ninf->ipow($inf),  $inf);
    is($ninf->ipow($ninf), $zero);
    is($ninf->ipow($zero), $one);
    is($ninf->ipow($one),  $ninf);
    is($ninf->ipow($mone), $zero);    # actually -0.0

    # MINUS ONE
    is($mone**$inf,  $one);
    is($mone**$ninf, $one);
    is($mone**$zero, $one);
    is($mone**$one,  $mone);
    is($mone**$mone, $mone);

    is($mone->ipow($inf),  $one);
    is($mone->ipow($ninf), $one);
    is($mone->ipow($zero), $one);
    is($mone->ipow($one),  $mone);
    is($mone->ipow($mone), $mone);

    # ZERO
    is($zero**$inf,  $zero);
    is($zero**$ninf, $inf);
    is($zero**$zero, $one);
    is($zero**$one,  $zero);
    is($zero**$mone, $inf);

    is($zero->ipow($inf),  $zero);
    is($zero->ipow($ninf), $inf);
    is($zero->ipow($zero), $one);
    is($zero->ipow($one),  $zero);
    is($zero->ipow($mone), $inf);

    # ONE
    is($one**$inf,  $one);
    is($one**$ninf, $one);
    is($one**$zero, $one);
    is($one**$one,  $one);
    is($one**$mone, $one);

    is($one->ipow($inf),  $one);
    is($one->ipow($ninf), $one);
    is($one->ipow($zero), $one);
    is($one->ipow($one),  $one);
    is($one->ipow($mone), $one);

    # POSITIVE INFINITY
    is($inf**$inf,  $inf);
    is($inf**$ninf, $zero);
    is($inf**$zero, $one);
    is($inf**$one,  $inf);
    is($inf**$mone, $zero);

    is($inf->ipow($inf),  $inf);
    is($inf->ipow($ninf), $zero);
    is($inf->ipow($zero), $one);
    is($inf->ipow($one),  $inf);
    is($inf->ipow($mone), $zero);

    # Make sure the constants are the same
    is($inf,  Math::BigNum->inf);
    is($ninf, Math::BigNum->ninf);
    is($zero, Math::BigNum->zero);
    is($one,  Math::BigNum->one);
    is($mone, Math::BigNum->mone);
}

# bpow()
{
    my $mone = Math::BigNum->new(-1);
    my $one  = Math::BigNum->new(1);
    my $zero = Math::BigNum->new(0);

    my $inf  = Math::BigNum->inf;
    my $ninf = Math::BigNum->ninf;

    # NEGATIVE INFINITY
    is($ninf->copy->bpow($inf),  $inf);
    is($ninf->copy->bpow($ninf), $zero);
    is($ninf->copy->bpow($zero), $one);
    is($ninf->copy->bpow($one),  $ninf);
    is($ninf->copy->bpow($mone), $zero);    # actually -0.0

    # MINUS ONE
    is($mone->copy->bpow($inf),  $one);
    is($mone->copy->bpow($ninf), $one);
    is($mone->copy->bpow($zero), $one);
    is($mone->copy->bpow($one),  $mone);
    is($mone->copy->bpow($mone), $mone);

    # ZERO
    is($zero->copy->bpow($inf),  $zero);
    is($zero->copy->bpow($ninf), $inf);
    is($zero->copy->bpow($zero), $one);
    is($zero->copy->bpow($one),  $zero);
    is($zero->copy->bpow($mone), $inf);

    # ONE
    is($one->copy->bpow($inf),  $one);
    is($one->copy->bpow($ninf), $one);
    is($one->copy->bpow($zero), $one);
    is($one->copy->bpow($one),  $one);
    is($one->copy->bpow($mone), $one);

    # POSITIVE INFINITY
    is($inf->copy->bpow($inf),  $inf);
    is($inf->copy->bpow($ninf), $zero);
    is($inf->copy->bpow($zero), $one);
    is($inf->copy->bpow($one),  $inf);
    is($inf->copy->bpow($mone), $zero);

    # Make sure the constants are the same
    is($inf,  Math::BigNum->inf);
    is($ninf, Math::BigNum->ninf);
    is($zero, Math::BigNum->zero);
    is($one,  Math::BigNum->one);
    is($mone, Math::BigNum->mone);
}

# bipow()
{
    my $mone = Math::BigNum->new(-1);
    my $one  = Math::BigNum->new(1);
    my $zero = Math::BigNum->new(0);

    my $inf  = Math::BigNum->inf;
    my $ninf = Math::BigNum->ninf;

    # NEGATIVE INFINITY
    is($ninf->copy->bipow($inf),  $inf);
    is($ninf->copy->bipow($ninf), $zero);
    is($ninf->copy->bipow($zero), $one);
    is($ninf->copy->bipow($one),  $ninf);
    is($ninf->copy->bipow($mone), $zero);    # actually -0.0

    # MINUS ONE
    is($mone->copy->bipow($inf),  $one);
    is($mone->copy->bipow($ninf), $one);
    is($mone->copy->bipow($zero), $one);
    is($mone->copy->bipow($one),  $mone);
    is($mone->copy->bipow($mone), $mone);

    # ZERO
    is($zero->copy->bipow($inf),  $zero);
    is($zero->copy->bipow($ninf), $inf);
    is($zero->copy->bipow($zero), $one);
    is($zero->copy->bipow($one),  $zero);
    is($zero->copy->bipow($mone), $inf);

    # ONE
    is($one->copy->bipow($inf),  $one);
    is($one->copy->bipow($ninf), $one);
    is($one->copy->bipow($zero), $one);
    is($one->copy->bipow($one),  $one);
    is($one->copy->bipow($mone), $one);

    # POSITIVE INFINITY
    is($inf->copy->bipow($inf),  $inf);
    is($inf->copy->bipow($ninf), $zero);
    is($inf->copy->bipow($zero), $one);
    is($inf->copy->bipow($one),  $inf);
    is($inf->copy->bipow($mone), $zero);

    # Make sure the constants are the same
    is($inf,  Math::BigNum->inf);
    is($ninf, Math::BigNum->ninf);
    is($zero, Math::BigNum->zero);
    is($one,  Math::BigNum->one);
    is($mone, Math::BigNum->mone);
}

##############################################################
# special integer truncations

is(Math::BigNum->new(-3)->ipow(-5),                    0);
is(Math::BigNum->new(-3)->ipow(Math::BigNum->new(-5)), 0);

is(Math::BigNum->new(-3)->ipow(-4),    0);
is(Math::BigNum->new(-3)->ipow($int2), 0);

is(Math::BigNum->new(-3)->bipow(-5),                    0);
is(Math::BigNum->new(-3)->bipow(Math::BigNum->new(-5)), 0);

is(Math::BigNum->new(-3)->bipow(-4),    0);
is(Math::BigNum->new(-3)->bipow($int2), 0);

is(Math::BigNum->new(-1)->ipow(-5),                    -1);
is(Math::BigNum->new(-1)->ipow(Math::BigNum->new(-5)), -1);

is(Math::BigNum->new(-1)->ipow(-4),    1);
is(Math::BigNum->new(-1)->ipow($int2), 1);

is(Math::BigNum->new(-1)->bipow(-5),                    -1);
is(Math::BigNum->new(-1)->bipow(Math::BigNum->new(-5)), -1);

is(Math::BigNum->new(-1)->bipow(-4),    1);
is(Math::BigNum->new(-1)->bipow($int2), 1);

##############################################################
# pow + int truncation

is(Math::BigNum->new(-3)->pow(-5)->bint,                    0);
is(Math::BigNum->new(-3)->pow(Math::BigNum->new(-5))->bint, 0);

is(Math::BigNum->new(-3)->pow(-4)->bint,    0);
is(Math::BigNum->new(-3)->pow($int2)->bint, 0);

is(Math::BigNum->new(-3)->bpow(-5)->bint,                    0);
is(Math::BigNum->new(-3)->bpow(Math::BigNum->new(-5))->bint, 0);

is(Math::BigNum->new(-3)->bpow(-4)->bint,    0);
is(Math::BigNum->new(-3)->bpow($int2)->bint, 0);

is(Math::BigNum->new(-1)->pow(-5)->bint,                    -1);
is(Math::BigNum->new(-1)->pow(Math::BigNum->new(-5))->bint, -1);

is(Math::BigNum->new(-1)->pow(-4)->bint,    1);
is(Math::BigNum->new(-1)->pow($int2)->bint, 1);

is(Math::BigNum->new(-1)->bpow(-5)->bint,                    -1);
is(Math::BigNum->new(-1)->bpow(Math::BigNum->new(-5))->bint, -1);

is(Math::BigNum->new(-1)->bpow(-4)->bint,    1);
is(Math::BigNum->new(-1)->bpow($int2)->bint, 1);

##############################################################
# fpow

{
    my $k = Math::BigNum->new(4.5);
    my $x = Math::BigNum->new(3.45);
    my $y = Math::BigNum->new(3);

    my $r1 = qr/^179\.3011/;
    my $r2 = qr/^91\.12[45]/;

    like($k->fpow("3.45"), $r1);
    like($k->fpow(3),      $r2);

    like($k->fpow($x), $r1);
    like($k->fpow($y), $r2);

    my $j = $k->copy;
    $j->bfpow($x);
    like($j, $r1);

    $j = $k->copy;
    $j->bfpow($y);
    like($j, $r2);

    $j = $k->copy;
    $j->bfpow("3.45");
    like($j, $r1);

    $j = $k->copy;
    $j->bfpow(3);
    like($j, $r2);
}

##############################################################
# real test

{
    use Math::BigNum qw(:constant);

    sub round_nth {
        my ($orig, $nth) = @_;

        my $n = abs($orig);
        my $p = 10**$nth;

        $n *= $p;
        $n += 0.5;

        if ($n == int($n) and $n % 2 != 0) {
            $n -= 0.5;
        }

        $n = int($n);
        $n /= $p;
        $n = -$n if ($orig < 0);

        return $n;
    }

    my @tests = (

        # original | rounded | places
        [+1.6,      +2,        0],
        [+1.5,      +2,        0],
        [+1.4,      +1,        0],
        [+0.6,      +1,        0],
        [+0.5,      0,         0],
        [+0.4,      0,         0],
        [-0.4,      0,         0],
        [-0.5,      0,         0],
        [-0.6,      -1,        0],
        [-1.4,      -1,        0],
        [-1.5,      -2,        0],
        [-1.6,      -2,        0],
        [3.016,     3.02,      2],
        [3.013,     3.01,      2],
        [3.015,     3.02,      2],
        [3.045,     3.04,      2],
        [3.04501,   3.05,      2],
        [-1234.555, -1000,     -3],
        [-1234.555, -1200,     -2],
        [-1234.555, -1230,     -1],
        [-1234.555, -1235,     0],
        [-1234.555, -1234.6,   1],
        [-1234.555, -1234.56,  2],
        [-1234.555, -1234.555, 3],
    );

    foreach my $pair (@tests) {
        my ($n, $expected, $places) = @$pair;
        my $rounded = round_nth($n, $places);

        is(ref($rounded), 'Math::BigNum');
        ok($rounded == $expected);
    }
}
