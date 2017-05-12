#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 159;

use Math::AnyNum;

my $int1 = Math::AnyNum->new(3);
my $int2 = Math::AnyNum->new(-4);

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
is("$r", "-1/64");

$r = $int2**(-$int1 + 1);
is("$r", "1/16");

#################################################################
# float + int

my $float1 = Math::AnyNum->new(3.45);
my $float2 = Math::AnyNum->new(-5.67);

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

$r = $float2**2.25;
like("$r", qr/^35\.078974175.*?\+35\.078974175.*?i\z/);

$r = 3**$float1;
like("$r", qr/^44\.2658011/);

$r = 1.23**$float2;
like("$r", qr/^0\.309198955/);

$r = 0**$float2;
is(lc("$r"), 'inf');

$r = Math::AnyNum->new(0)**$int2;
is(lc("$r"), 'inf');

$r = Math::AnyNum->new(0)**$int1;
is("$r", "0");

$r = 0**($int2 - 1);
is(lc("$r"), 'inf');

{
    my $n = Math::AnyNum->new('12.6');
    $n = $n->pow('3.45');
    like("$n", qr/^6255\.735538995494576076354865979491381\d*\z/);
}

{
    my $n = Math::AnyNum->new('12.6');
    $n = $n->pow('3.45');
    like("$n", qr/^6255\.735538995494576076354865979491381\d*\z/);
}

{
    my $n = Math::AnyNum->new('12.6');
    $n = $n->ipow('3.45');
    is("$n", "1728");
}

##############################################################
# special values
# See: https://en.wikipedia.org/wiki/NaN#Operations_generating_NaN

{
    use Math::AnyNum qw(:overload);

    # AnyNum
    is(0**0,               1);
    is(0**Inf,             0);
    is(0**(-Inf),          Inf);
    is(ref(0**0),          'Math::AnyNum');    # make sure we're getting AnyNum objects
    is(1**Inf,             1);
    is((-1)**Inf,          1);
    is(1**(-Inf),          1);
    is((-1)**(-Inf),       1);
    is(Inf**0,             1);
    is((-Inf)**0,          1);
    is((-Inf)**2,          Inf);
    is((-Inf)**3,          -Inf);
    is((-Inf)**2.3,        'Inf+NaNi');
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
    is((-Inf)**(1 / (2)), 'Inf+NaNi');
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
    is((-Inf)**"2.3",          'Inf+NaNi');
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

{
    my $mone = Math::AnyNum->new(-1);
    my $one  = Math::AnyNum->new(1);
    my $zero = Math::AnyNum->new(0);

    my $inf  = Math::AnyNum->inf;
    my $ninf = Math::AnyNum->ninf;

    # NEGATIVE INFINITY
    is($ninf**$inf,  $inf);
    is($ninf**$ninf, $zero);
    is($ninf**$zero, $one);
    is($ninf**$one,  $ninf);
    is($ninf**$mone, $zero);    # actually -0.0

    is($ninf->ipow($inf),  'NaN');    # should be Inf?
    is($ninf->ipow($ninf), 'NaN');    # should be 0?
    is($ninf->ipow($zero), 'NaN');    # should be 1?
    is($ninf->ipow($one),  'NaN');    # should be -Inf?
    is($ninf->ipow($mone), 'NaN');    # should be 0?

    # MINUS ONE
    is($mone**$inf,  $one);
    is($mone**$ninf, $one);
    is($mone**$zero, $one);
    is($mone**$one,  $mone);
    is($mone**$mone, $mone);

    is($mone->ipow($inf),  'NaN');    # should be 1?
    is($mone->ipow($ninf), 'NaN');    # should be 1?
    is($mone->ipow($zero), $one);
    is($mone->ipow($one),  $mone);
    is($mone->ipow($mone), $mone);

    # ZERO
    is($zero**$inf,  $zero);
    is($zero**$ninf, $inf);
    is($zero**$zero, $one);
    is($zero**$one,  $zero);
    is($zero**$mone, $inf);

    is($zero->ipow($inf),  'NaN');    # should be 0?
    is($zero->ipow($ninf), 'NaN');    # should be Inf?
    is($zero->ipow($zero), $one);
    is($zero->ipow($one),  $zero);
    is($zero->ipow($mone), $inf);

    # ONE
    is($one**$inf,  $one);
    is($one**$ninf, $one);
    is($one**$zero, $one);
    is($one**$one,  $one);
    is($one**$mone, $one);

    is($one->ipow($inf),  'NaN');     # should be 1?
    is($one->ipow($ninf), 'NaN');     # should be 1?
    is($one->ipow($zero), $one);
    is($one->ipow($one),  $one);
    is($one->ipow($mone), $one);

    # POSITIVE INFINITY
    is($inf**$inf,  $inf);
    is($inf**$ninf, $zero);
    is($inf**$zero, $one);
    is($inf**$one,  $inf);
    is($inf**$mone, $zero);

    is($inf->ipow($inf),  'NaN');     # should be Inf?
    is($inf->ipow($ninf), 'NaN');     # should be 0?
    is($inf->ipow($zero), 'NaN');     # should be 1?
    is($inf->ipow($one),  'NaN');     # should be Inf?
    is($inf->ipow($mone), 'NaN');     # should be 0?

    # Make sure the constants are the same
    is($inf,  Math::AnyNum->inf);
    is($ninf, Math::AnyNum->ninf);
    is($zero, Math::AnyNum->zero);
    is($one,  Math::AnyNum->one);
    is($mone, Math::AnyNum->mone);
}

##############################################################
# special integer truncations

is(Math::AnyNum->new(-3)->ipow(-5),                    0);
is(Math::AnyNum->new(-3)->ipow(Math::AnyNum->new(-5)), 0);

is(Math::AnyNum->new(-3)->ipow(-4),    0);
is(Math::AnyNum->new(-3)->ipow($int2), 0);

is(Math::AnyNum->new(-1)->ipow(-5),                    -1);
is(Math::AnyNum->new(-1)->ipow(Math::AnyNum->new(-5)), -1);

is(Math::AnyNum->new(-1)->ipow(-4),    1);
is(Math::AnyNum->new(-1)->ipow($int2), 1);

##############################################################
# pow + int truncation

is(Math::AnyNum->new(-3)->pow(-5)->int,                    0);
is(Math::AnyNum->new(-3)->pow(Math::AnyNum->new(-5))->int, 0);

is(Math::AnyNum->new(-3)->pow(-4)->int,    0);
is(Math::AnyNum->new(-3)->pow($int2)->int, 0);

is(Math::AnyNum->new(-1)->pow(-5)->int,                    -1);
is(Math::AnyNum->new(-1)->pow(Math::AnyNum->new(-5))->int, -1);

is(Math::AnyNum->new(-1)->pow(-4)->int,    1);
is(Math::AnyNum->new(-1)->pow($int2)->int, 1);
