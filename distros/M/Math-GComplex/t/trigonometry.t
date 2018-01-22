#!perl -T

use 5.010;
use strict;
use warnings;
use Test::More;

## Tests from Math::Complex / Math::Trig (+ some additional ones)
## https://metacpan.org/source/ZEFRAM/Math-Complex-1.59/t/Trig.t

use Math::GComplex qw(:trig :special i);

plan tests => 150;

my $eps = 1e-10;

sub near ($$;$) {
    my $e = $_[2] // $eps;
    my $d = $_[1] ? abs($_[0] / $_[1] - 1) : abs($_[0]);
    $_[1] ? ($d < $e) : abs($_[0]) < $e;
}

ok(near(sin(1), 0.841470984807897));
ok(near(cos(1), 0.54030230586814));
ok(near(tan(1), 1.5574077246549));

ok(near(sec(1), 1.85081571768093));
ok(near(csc(1), 1.18839510577812));
ok(near(cot(1), 0.642092615934331));

ok(near(asin(1), 1.5707963267949));
ok(near(acos(1), 0));
ok(near(atan(1), 0.785398163397448));

ok(near(asec(1), 0));
ok(near(acsc(1), 1.5707963267949));
ok(near(acot(1), 0.785398163397448));

ok(near(sinh(1), 1.1752011936438));
ok(near(cosh(1), 1.54308063481524));
ok(near(tanh(1), 0.761594155955765));

ok(near(sech(1), 0.648054273663885));
ok(near(csch(1), 0.850918128239322));
ok(near(coth(1), 1.31303528549933));

ok(near(asinh(1),   0.881373587019543));
ok(near(acosh(1),   0));
ok(near(atanh(0.9), 1.47221948958322));

ok(near(asech(0.9), 0.467145308103262));
ok(near(acsch(2),   0.481211825059603));
ok(near(acoth(2),   0.549306144334055));

my $x = 0.9;
ok(near(tan($x), sin($x) / cos($x)));

ok(near(sinh(2),    3.62686040784702));
ok(near(acsch(0.1), 2.99822295029797));

$x = asin(2);
is(ref($x), 'Math::GComplex');

my ($y, $z) = $x->reals;
ok(near($y, 1.5707963267949));
ok(near($z, -1.31695789692482));

ok(near(deg2rad(90), atan2(0, -1) / 2));
ok(near(rad2deg(atan2(0, -1)), 180));

is(deg2rad(0), '(0 0)');
is(rad2deg(0), '(0 0)');

ok(near(deg2rad(-45), -atan2(0, -1) / 4));
ok(near(rad2deg(-atan2(0, -1) / 4), -45));

is(deg2rad(rad2deg(-10)), '(-10 0)');
is(rad2deg(deg2rad(-10)), '(-10 0)');

is(deg2rad(rad2deg(0)), '(0 0)');
is(rad2deg(deg2rad(0)), '(0 0)');

ok(near(sinh(100), 1.3441e+43, 1e-3));
ok(near(sech(100), 7.4402e-44, 1e-3));
ok(near(cosh(100), 1.3441e+43, 1e-3));
ok(near(csch(100), 7.4402e-44, 1e-3));
ok(near(tanh(100), 1));
ok(near(coth(100), 1));

ok(near(sinh(-100), -1.3441e+43, 1e-3));
ok(near(sech(-100), 7.4402e-44,  1e-3));
ok(near(cosh(-100), 1.3441e+43,  1e-3));
ok(near(csch(-100), -7.4402e-44, 1e-3));
ok(near(tanh(-100), -1));
ok(near(coth(-100), -1));

#cmp_ok(sech(1e5), '==', 0);
#cmp_ok(csch(1e5), '==', 0);
#cmp_ok(tanh(1e5), '==', 1);
#cmp_ok(coth(1e5), '==', 1);

cmp_ok(sech(-1e5), '==', 0);
cmp_ok(csch(-1e5), '==', 0);
cmp_ok(tanh(-1e5), '==', -1);
cmp_ok(coth(-1e5), '==', -1);

#~ ok(acos(-2.0)->real == 4 * atan2(4, 4));
#~ ok(acos(-1.0)->real == 4 * atan2(4, 4));
#~ ok(acos(-0.5)->real == acos(-0.5));
#~ ok(acos(0.0)->real == 2 * atan2(4, 4));
#~ ok(acos(0.5)->real == acos(0.5));
#~ ok(acos(1.0)->real == 0);
#~ ok(near(acos(2.0)->real, 0));

#~ ok(asin(-0.5)->real == asin(-0.5));
#~ ok(asin(0.0)->real == asin(0.0));
#~ ok(asin(0.5)->real == asin(0.5));

for my $iter (1 .. 3) {

    my $z = Math::GComplex->new(rand(5), rand(5));
    my $n = Math::GComplex->new(rand(5), rand(5));

    if ($iter == 2) {
        eval { require Math::AnyNum; };

        if (!$@) {
            $z->{a} = Math::AnyNum::rand(5);
            $z->{b} = Math::AnyNum::rand(5);

            $n->{a} = Math::AnyNum::rand(5);
            $n->{b} = Math::AnyNum::rand(5);
        }
    }

    if (rand(1) < 0.5) {
        $z->{a} = -$z->{a};
    }

    if (rand(1) < 0.5) {
        $z->{b} = -$z->{a};
    }

    ok(near(cbrt($z), $z**(1 / 3)));
    ok(near(cbrt($z), root($z, 3)));

    ok(near(logn($z, $n), log($z) / log($n)));

    ok(near(tan($z), sin($z) / cos($z)));

    ok(near(csc($z), 1 / sin($z)));
    ok(near(sec($z), 1 / cos($z)));

    ok(near(cot($z), 1 / tan($z)));

    ok(near(asin($z), -i * log(i * $z + sqrt(1 - $z**2))));
    ok(near(acos($z), -i * log($z + i * sqrt(1 - $z**2))));

    ok(near(atan($z), i / 2 * log((i + $z) / (i- $z))));

    ok(near(acsc($z), asin(1 / $z)));
    ok(near(asec($z), acos(1 / $z)));
    ok(near(acot($z), atan(1 / $z)));
    ok(near(acot($z), -i / 2 * log((i + $z) / ($z -i))));

    ok(near(sinh($z), 1 / 2 * (exp($z) - exp(-$z))));
    ok(near(cosh($z), 1 / 2 * (exp($z) + exp(-$z))));
    ok(near(tanh($z), sinh($z) / cosh($z)));
    ok(near(tanh($z), (exp($z) - exp(-$z)) / (exp($z) + exp(-$z))));

    ok(near(csch($z), 1 / sinh($z)));
    ok(near(sech($z), 1 / cosh($z)));
    ok(near(coth($z), 1 / tanh($z)));

    ok(near(asinh($z), log($z + sqrt($z**2 + 1))));
    ok(near(acosh($z), log($z + sqrt($z - 1) * sqrt($z + 1))));
    ok(near(atanh($z), 1 / 2 * log((1 + $z) / (1 - $z))));

    ok(near(acsch($z), asinh(1 / $z)));
    ok(near(asech($z), acosh(1 / $z)));
    ok(near(acoth($z), atanh(1 / $z)));
    ok(near(acoth($z), 1 / 2 * log((1 + $z) / ($z - 1))));
}

# More trigonometric tests
#   http://rosettacode.org/wiki/Trigonometric_functions#Perl

{
    my $theta = atan2(0, -1) / 4;

    ok(near(sin($theta), 0.707106781186547), 'sin(x)');
    ok(near(cos($theta), 0.707106781186548), 'cos(x)');

    is(tan($theta), '(1 0)', 'tan(x)');
    is(cot($theta), '(1 0)', 'cot(x)');

    ok(near(asin(sin($theta)), 0.785398163397448), 'asin(sin(x))');
    ok(near(acos(cos($theta)), 0.785398163397448), 'acos(cos(x))');
    ok(near(atan(tan($theta)), 0.785398163397448), 'atan(tan(x))');
    ok(near(acot(cot($theta)), 0.785398163397448), 'acot(cot(x))');
    ok(near(asec(sec($theta)), 0.785398163397448), 'asec(sec(x))');
    ok(near(acsc(csc($theta)), 0.785398163397448), 'acsc(csc(x))');
}
