#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 586;

use Math::AnyNum qw(:ntheory);
use Math::GMPz::V qw();

my $GMP_V_MAJOR = Math::GMPz::V::___GNU_MP_VERSION();
my $GMP_V_MINOR = Math::GMPz::V::___GNU_MP_VERSION_MINOR();

my $o = 'Math::AnyNum';

is(lucas(-1),            'NaN');
is(lucas(0),             '2');
is(lucas(1),             '1');
is(lucas(15),            '1364');
is(lucas($o->new('15')), '1364');
is(lucas($o->new('-4')), 'NaN');

is(lucasU(4, 4, 13), '53248');
is(lucasV(4, 4, 13), '16384');

is(lucasV(-4, 4,  24), '33554432');
is(lucasV(4,  -4, 24), '25783171895263232');
is(lucasV(4,  -4, 25), '124492166541082624');
is(lucasV(-4, 4,  25), '-67108864');
is(lucasV(-4, 4,  26), '134217728');
is(lucasV(-4, -4, 16), '87275208704');
is(lucasV(-4, -4, 48), '664771952980691802270648617664512');

is(lucasU(4,  -4, 24), '4557863921909760');
is(lucasU(-4, 4,  24), '-201326592');
is(lucasU(4,  -4, 25), '22007313791451136');
is(lucasU(-4, 4,  25), '419430400');
is(lucasU(-4, 4,  26), '-872415232');
is(lucasU(-4, -4, 16), '-15428222976');
is(lucasU(-4, -4, 48), '-117516188973817974394087349944320');

is(join(' ', map { lucasU(1, -1, $_) } 0 .. 10), '0 1 1 2 3 5 8 13 21 34 55');
is(join(' ', map { lucasV(1, -1, $_) } 0 .. 10), '2 1 3 4 7 11 18 29 47 76 123');

is(join(', ', map { lucasU(3, 4, $_) } 0 .. 9), '0, 1, 3, 5, 3, -11, -45, -91, -93, 85');
is(join(', ', map { lucasV(3, 4, $_) } 0 .. 9), '2, 3, 1, -9, -31, -57, -47, 87, 449, 999');

is(join(', ', map { lucasU(3, -2, $_) } 0 .. 9), '0, 1, 3, 11, 39, 139, 495, 1763, 6279, 22363');
is(join(', ', map { lucasV(3, -2, $_) } 0 .. 9), '2, 3, 13, 45, 161, 573, 2041, 7269, 25889, 92205');

is(join(', ', map { lucasU(4, 4, $_) } 0 .. 9), '0, 1, 4, 12, 32, 80, 192, 448, 1024, 2304');
is(join(', ', map { lucasV(4, 4, $_) } 0 .. 9), '2, 4, 8, 16, 32, 64, 128, 256, 512, 1024');

is(lucasUmod(-4, -4, 48,    '700237709'),  '424976705');
is(lucasUmod(4,  -4, 4171,  '619442071'),  '93411036');
is(lucasUmod(4,  -4, 54223, '1238884142'), '793124222');

is(lucasUmod(5, 3, 1234, '789347'),  '134939');
is(lucasUmod(5, 3, 1234, '-789347'), '134939');

is(join(', ', map { lucasUmod(3, -2, $_, 24) } 0 .. 9), '0, 1, 3, 11, 15, 19, 15, 11, 15, 19');
is(join(', ', map { lucasVmod(3, -2, $_, 24) } 0 .. 9), '2, 3, 13, 21, 17, 21, 1, 21, 17, 21');

is(join(', ', map { lucasUmod(4, 4, $_, 25) } 0 .. 9), '0, 1, 4, 12, 7, 5, 17, 23, 24, 4');
is(join(', ', map { lucasVmod(4, 4, $_, 25) } 0 .. 9), '2, 4, 8, 16, 7, 14, 3, 6, 12, 24');

is(join(', ', map { lucasUmod(-5, -3, $_, 48) } 0 .. 9), '0, 1, 43, 28, 37, 43, 40, 25, 43, 4');
is(join(', ', map { lucasVmod(-5, -3, $_, 48) } 0 .. 9), '2, 43, 31, 22, 31, 7, 10, 19, 31, 46');

#<<<
is(join(', ', map { lucasUmod( 5, 3, $_, 789347) } 0 .. 14), '0, 1, 5, 22, 95, 409, 1760, 7573, 32585, 140206, 603275, 227716, 118102, 696709, 761198');
is(join(', ', map { lucasUmod(-5, 3, $_, 789347) } 0 .. 14), '0, 1, 789342, 22, 789252, 409, 787587, 7573, 756762, 140206, 186072, 227716, 671245, 696709, 28149');
#>>>

is(factorial(0),          '1');
is(factorial(5),          '120');
is(factorial(-1),         'NaN');
is(factorial($o->new(5)), '120');

is(fibonacci(0),           '0');
is(fibonacci(12),          '144');
is(fibonacci(-3),          'NaN');
is(fibonacci($o->new(12)), '144');

#<<<
is(join(' ', map { fibonacci($_, 3) } 0 .. 14),                                             '0 0 1 1 2 4 7 13 24 44 81 149 274 504 927');
is(join(' ', map { fibonacci(Math::AnyNum->new_ui($_), Math::AnyNum->new_ui(4)) } 0 .. 14), '0 0 0 1 1 2 4 8 15 29 56 108 208 401 773');
#>>>

{
    my $t = ipow2(127) - 1;
    is(lucasmod($t, $t), 1);
    is(fibmod($t, $t), $t - 1);
}

{
    my $t = ipow10(15);
    is(fibmod(105, $t), fibonacci(105) % $t);
    is(lucasmod(105, $t), lucas(105) % $t);
}

is(fibmod(0, 100), 0);
is(fibmod(1, 100), 1);
is(lucasmod(0, 100), 2);
is(lucasmod(1, 100), 1);

is(lucasUmod(1, -1, 0, 100), 0);
is(lucasUmod(1, -1, 1, 100), 1);

is(lucasVmod(1, -1, 0, 100), 2);
is(lucasVmod(1, -1, 1, 100), 1);

is(lucasUmod(4, 4, 0, 100), 0);
is(lucasUmod(4, 4, 1, 100), 1);

is(lucasUmod(4, 4,  50, 1000), lucasU(4, 4,  50) % 1000);
is(lucasUmod(4, -4, 50, 1000), lucasU(4, -4, 50) % 1000);

is(lucasVmod(4, 4, 0, 100), 2);
is(lucasVmod(4, 4, 1, 100), 4);

is(lucasVmod(4, 4, 0, 100), lucasV(4, 4, 0) % 100);
is(lucasVmod(4, 4, 1, 100), lucasV(4, 4, 1) % 100);

is(lucasVmod(4,  4, 50, 1000), 248);
is(lucasVmod(-4, 4, 50, 1000), 248);

is(lucasVmod(4,  4, 50, 1000), lucasV(4, 4, 50) % 1000);
is(lucasVmod(-4, 4, 50, 1000), lucasV(4, 4, 50) % 1000);

is(lucasVmod(4,  4, 50, 1001), lucasV(4,  4, 50) % 1001);
is(lucasVmod(-4, 4, 50, 1001), lucasV(-4, 4, 50) % 1001);

is(lucasVmod(4,  -4, 50, 1000), 624);
is(lucasVmod(-4, -4, 50, 1000), 624);

is(lucasVmod(4,  -4, 50, 1000), lucasV(4,  -4, 50) % 1000);
is(lucasVmod(-4, -4, 50, 1000), lucasV(-4, -4, 50) % 1000);

is(fibmod(1234, 987654), fibonacci(1234) % 987654);
is(lucasmod(1234, 987654), lucas(1234) % 987654);

is(fibmod(-1, 1234), 'NaN');
is(lucasmod(-1, 1234), 'NaN');

is(fibmod(42, 0), 'NaN');
is(lucasmod(42, 0), 'NaN');

{
    my $x = Math::AnyNum->new('1/3');

    is(chebyshevT(0, $x), 1);
    is(chebyshevT(1, $x), $x);
    is(chebyshevT(2, $x), 2 * $x * $x - 1);

    is(chebyshevU(0, $x), 1);
    is(chebyshevU(1, $x), 2 * $x);
    is(chebyshevU(2, $x), 4 * $x * $x - 1);

    is(chebyshevT(4, -$x), (-1)**4 * chebyshevT(4, $x));
    is(chebyshevT(5, -$x), (-1)**5 * chebyshevT(5, $x));

    is(chebyshevU(4, -$x), (-1)**4 * chebyshevU(4, $x));
    is(chebyshevU(5, -$x), (-1)**5 * chebyshevU(5, $x));

    $x = Math::AnyNum->new('-7/11');

    is(chebyshevT(Math::AnyNum->new(10), $x), '-21191511863/25937424601');
    is(chebyshevT(Math::AnyNum->new(11), $x), '275243014193/285311670611');

    is(chebyshevU(Math::AnyNum->new(10), $x), '-8853775501/25937424601');
    is(chebyshevU(Math::AnyNum->new(11), $x), '337219442700/285311670611');

    is(chebyshevT(-1,                    $x), '-7/11');
    is(chebyshevT(-2,                    $x), '-23/121');
    is(chebyshevT(-3,                    $x), '1169/1331');
    is(chebyshevT(Math::AnyNum->new(-4), $x), '-13583/14641');

    is(chebyshevU(-1,                    $x), 0);
    is(chebyshevU(-2,                    $x), -1);
    is(chebyshevU(-3,                    $x), '14/11');
    is(chebyshevU(Math::AnyNum->new(-4), $x), '-75/121');

    is(chebyshevT(4, -$x), (-1)**4 * chebyshevT(4, $x));
    is(chebyshevT(5, -$x), (-1)**5 * chebyshevT(5, $x));

    is(chebyshevU(4, -$x), (-1)**4 * chebyshevU(4, $x));
    is(chebyshevU(5, -$x), (-1)**5 * chebyshevU(5, $x));

    is(chebyshevT(4.7, -$x), (-1)**4 * chebyshevT(4, $x));    # 4.7 gets truncated to 4
    is(chebyshevU(4.7, -$x), (-1)**4 * chebyshevU(4, $x));    # =//=

    is(chebyshevT(Math::AnyNum->new(4.7), -$x), (-1)**4 * chebyshevT(4, $x));    # 4.7 gets truncated to 4
    is(chebyshevU(Math::AnyNum->new(4.7), -$x), (-1)**4 * chebyshevU(4, $x));    # =//=

    is(chebyshevT(5, cos($x)), cos($x * 5));
    is(chebyshevU(5, cos($x)), sin(6 * $x) / sin($x));
}

{
    # LaguerreL(n,x)
    my $x = Math::AnyNum->new('7/5');
    my $y = Math::AnyNum->new('-5/9');
    my $t = Math::AnyNum->new(12);

    is(join(', ', map { laguerreL($_, $x) } 0 .. 5), '1, -2/5, -41/50, -269/375, -5839/15000, -3341/187500');
    is(join(', ', map { laguerreL($_, $y) } 0 .. 5), '1, 14/9, 367/162, 6907/2187, 671809/157464, 3987263/708588');

    is(laguerreL($t, 5) * factorial(12), '-693883775');

    # LegendreP(n,x)
    is(join(', ', map { legendreP($_, $x) } 0 .. 5), '1, 7/5, 61/25, 119/25, 1229/125, 65527/3125');
    is(join(', ', map { legendreP($_, $y) } 0 .. 5), '1, -5/9, -1/27, 295/729, -2399/6561, 275/6561');

    is(legendreP($t, 5), '143457011569');

    # HermiteH(n,x)
    is(join(', ', map { hermiteH($_, $x) } 0 .. 5), '1, 14/5, 146/25, 644/125, -12884/625, -309176/3125');
    is(join(', ', map { hermiteH($_, $y) } 0 .. 5), '1, -10/9, -62/81, 3860/729, -8468/6561, -2416600/59049');

    is(hermiteH($t, 5), '171237081280');

    # HermiteHe(n, x)
    is(join(', ', map { hermiteHe($_, $x) } 0 .. 5), '1, 7/5, 24/25, -182/125, -3074/625, -3318/3125');
    is(join(', ', map { hermiteHe($_, $y) } 0 .. 5), '1, -5/9, -56/81, 1090/729, 8158/6561, -393950/59049');

    is(hermiteHe($t, 5), '-5939480');
}

is(binomial(12,           5),           '792');
is(binomial(0,            0),           '1');
is(binomial(-15,          12),          '9657700');
is(binomial($o->new(-15), $o->new(12)), '9657700');
is(binomial($o->new(-15), 12),          '9657700');
is(binomial(-15,          $o->new(12)), '9657700');
is(binomial(124,          -2),          '0');
is(binomial(-124,         -3),          '0');

is(binomial($o->new(12),  5),           '792');
is(binomial(-15,          $o->new(12)), '9657700');
is(binomial($o->new(124), $o->new(-2)), '0');

is(divmod($o->new(1234), 100),           34);
is(divmod(12345,         1000),          345);
is(divmod(12345,         $o->new(1000)), 345);

is(binomial(42, 39),  11480);
is(binomial(-4, -42), 10660);
is(binomial(-4, 42),  14190);

is(binomial(42,          $o->new(39)), 11480);
is(binomial($o->new(42), 39),          11480);
is(binomial($o->new(42), $o->new(39)), 11480);

is(fibonacci(12), 144);
is(lucas(15),     1364);

is(falling_factorial(123,          13),          '764762377697592310465228800');
is(falling_factorial(123,          $o->new(13)), '764762377697592310465228800');
is(falling_factorial($o->new(123), 13),          '764762377697592310465228800');
is(falling_factorial($o->new(123), $o->new(13)), '764762377697592310465228800');

is(rising_factorial(123,          13),          '2724517128835670795827200000');
is(rising_factorial(123,          $o->new(13)), '2724517128835670795827200000');
is(rising_factorial($o->new(123), 13),          '2724517128835670795827200000');
is(rising_factorial($o->new(123), $o->new(13)), '2724517128835670795827200000');

is(falling_factorial(-123,          13),          '-2724517128835670795827200000');
is(falling_factorial(-123,          $o->new(13)), '-2724517128835670795827200000');
is(falling_factorial($o->new(-123), 13),          '-2724517128835670795827200000');
is(falling_factorial($o->new(-123), $o->new(13)), '-2724517128835670795827200000');

is(rising_factorial(-123,          13),          '-764762377697592310465228800');
is(rising_factorial(-123,          $o->new(13)), '-764762377697592310465228800');
is(rising_factorial($o->new(-123), 13),          '-764762377697592310465228800');
is(rising_factorial($o->new(-123), $o->new(13)), '-764762377697592310465228800');

is(falling_factorial(-123, -13), '-1/683933833713293936188416000');
is(rising_factorial(-123, -13), '-1/3012474223753262018150400000');

is(rising_factorial(12, -13), 'NaN');
is(falling_factorial(-13, -14), 'NaN');

is(superfactorial(-1), 'NaN');
is(hyperfactorial(-1), 'NaN');

is(join(', ', map { superfactorial($_) } 0 .. 7), '1, 1, 2, 12, 288, 34560, 24883200, 125411328000');
is(join(', ', map { hyperfactorial($_) } 0 .. 7), '1, 1, 4, 108, 27648, 86400000, 4031078400000, 3319766398771200000');

is(bell(-1),    'NaN');
is(catalan(-1), 'NaN');

is(join(', ', map { catalan($_) } 0 .. 10), '1, 1, 2, 5, 14, 42, 132, 429, 1430, 4862, 16796');
is(join(', ', map { bell($_) } 0 .. 10),    '1, 1, 2, 5, 15, 52, 203, 877, 4140, 21147, 115975');

is(catalan(5,           0),           1);
is(catalan(5,           1),           5);
is(catalan(1,           $o->new(1)),  1);
is(catalan($o->new(8),  3),           110);
is(catalan($o->new(8),  -3),          'NaN');
is(catalan($o->new(8),  $o->new(-3)), 'NaN');
is(catalan($o->new(-8), 3),           -50);
is(catalan($o->new(4),  $o->new(4)),  14);
is(catalan(2,           $o->new(3)),  0);

is(bell($o->new(30)),    '846749014511809332450147');
is(catalan($o->new(45)), '2257117854077248073253720');

#<<<
is(falling_factorial(123, $o->new(-42)),          '1/4465482258831228787047309106389002878492944333613461706826678255930625748893696000000000000');
is(falling_factorial($o->new(123), $o->new(-42)), '1/4465482258831228787047309106389002878492944333613461706826678255930625748893696000000000000');
#>>>

#<<<
is(rising_factorial(123, $o->new(-42)),          '1/1379784702635118873851443870763273422674515081030831950911803668709291065344000000000');
is(rising_factorial($o->new(123), $o->new(-42)), '1/1379784702635118873851443870763273422674515081030831950911803668709291065344000000000');
#>>>

# The following functions require GMP >= 5.1.0.
#   primorial
#   dfactorial
#   mfactorial

SKIP: {
    my $OLD_GMP = ($GMP_V_MAJOR < 5 or ($GMP_V_MAJOR == 5 and $GMP_V_MINOR < 1));

    # Update this counter when more tests are added or deleted in this section
    skip("old version of GMP detected", 18) if $OLD_GMP;

    is(mfactorial(10, 2), '3840');
    is(mfactorial(11, 3), '880');

    is(mfactorial($o->new(10), 2),          '3840');
    is(mfactorial(11,          $o->new(2)), '10395');
    is(mfactorial($o->new(10), $o->new(2)), '3840');

    is(mfactorial(-3, -23), 'NaN');
    is(mfactorial(-3, 23),  'NaN');
    is(mfactorial(3,  -23), 'NaN');

    is(mfactorial($o->new(-3), $o->new(-23)), 'NaN');
    is(mfactorial($o->new(-3), 23),           'NaN');
    is(mfactorial(3,           $o->new(-23)), 'NaN');
    is(mfactorial($o->new(3),  -23),          'NaN');

    is(dfactorial(10),          '3840');
    is(dfactorial($o->new(11)), '10395');

    is(primorial(15),            '30030');
    is(primorial(-5),            'NaN');
    is(primorial($o->new('15')), '30030');
    is(primorial($o->new('-6')), 'NaN');
}

is(fibonacci($o->new(12)), 144);
is(lucas($o->new(15)),     1364);

is(ipow(2,  10), 1024);
is(ipow(-2, 10), 1024);
is(ipow(-2, 11), -2048);
is(ipow(-2, -1), 0);
is(ipow(-2, -2), 0);
is(ipow(-1, -1), -1);
is(ipow(-1, 0),  1);

is(ipow(2,   10.5), 1024);
is(ipow(2.5, 10.5), 1024);
is(ipow(2.5, 10),   1024);

is(ipow(2,          $o->new(10)), 1024);
is(ipow($o->new(2), 10),          1024);
is(ipow($o->new(2), $o->new(10)), 1024);

is(ipow(2,            $o->new(10.5)), 1024);
is(ipow($o->new(2.5), 10.5),          1024);
is(ipow($o->new(2),   10.5),          1024);
is(ipow($o->new(2.5), $o->new(10)),   1024);
is(ipow($o->new(2.5), 10),            1024);

is(ipow2(0),               1);
is(ipow2(3),               8);
is(ipow2(-3),              0);
is(ipow2(3.5),             8);
is(ipow2(3.7),             8);
is(ipow2($o->new('3.7')),  8);
is(ipow2($o->new('13/2')), 64);
is(ipow2($o->new(-1)),     0);
is(ipow2($o->new(5)),      32);

is(ipow10(0),               1);
is(ipow10(3),               1000);
is(ipow10(-3),              0);
is(ipow10(3.7),             1000);
is(ipow10(3.5),             1000);
is(ipow10($o->new(-3)),     0);
is(ipow10($o->new(3)),      1000);
is(ipow10($o->new('13/2')), 1000000);
is(ipow10($o->new('3.7')),  1000);

is(lcm(),   1);
is(lcm(42), 42);
is(lcm(13,          14),          182);
is(lcm(14,          $o->new(13)), 182);
is(lcm($o->new(14), 13),          182);
is(lcm($o->new(13), $o->new(14)), 182);

is(lcm($o->new(42), "1210923789812382173912783"), '7265542738874293043476698');
is(lcm(42,          "1210923789812382173912783"), '7265542738874293043476698');

is(lcm(12, -28),          84);
is(lcm(12, $o->new(-28)), 84);
is(lcm(4, 9, 13, 11), 5148);

ok(is_coprime(27,          8));
ok(is_coprime(8,           27));
ok(is_coprime($o->new(27), 8));
ok(is_coprime($o->new(27), $o->new(8)));
ok(is_coprime(27,          $o->new(8)));

ok(!is_coprime(42,         6));
ok(!is_coprime(6,          42));
ok(!is_coprime($o->new(6), 42));
ok(!is_coprime($o->new(6), $o->new(42)));
ok(!is_coprime(6,          $o->new(42)));

is(gcd(),   0);
is(gcd(42), 42);
is(gcd(20,          12),          4);
is(gcd($o->new(20), 12),          4);
is(gcd(20,          $o->new(12)), 4);
is(gcd($o->new(12), $o->new(20)), 4);

is(join(' ', gcdext(12,  20)),  '2 -1 4');
is(join(' ', gcdext(196, 147)), '1 -1 49');
is(join(' ', gcdext(147, 196)), '-1 1 49');

is(gcd(42,   98,   8),   2);
is(gcd(5040, 5020, -50), 10);
is(gcd(5040, 5020, 49, 124), 1);

is(gcd(8993, -207),          23);
is(gcd(8993, $o->new(-207)), 23);

is(gcd($o->new(42), "1210923789812382173912783"), 7);
is(gcd(42,          "1210923789812382173912783"), 7);

is(bernfrac(-2),          'NaN');
is(bernfrac(-1),          'NaN');
is(bernfrac(0),           1);
is(bernfrac(1),           '1/2');
is(bernfrac(30),          '8615841276005/14322');
is(bernfrac($o->new(30)), '8615841276005/14322');
is(bernfrac(52),          '-801165718135489957347924991853/1590');
is(bernfrac(54),          '29149963634884862421418123812691/798');
is(bernfrac($o->new(54)), '29149963634884862421418123812691/798');

#<<<
is(bernfrac(90), '1179057279021082799884123351249215083775254949669647116231545215727922535/272118');
is(bernfrac(92), '-1295585948207537527989427828538576749659341483719435143023316326829946247/1410');
#>>>

#<<<
is(bernfrac(502), '38142160866467232884554309224034651634093138120562408229937284335262462582150075796219859552052172031621040304395639116490006921543478655667154940739556377503624120354277544396762810887962942382325268406917540639101080669724764495814187297806062515207318249672295291766329723921826377856515614624615956440515767735038166213859359258260596787181638471860235900018041798849234264568412537290039238616166689649555178242643505175730845234684718491759030264918961278228933277428217322561407632723029650720023471432310416563550665717641718762997568990168391379348328588305018146978038035813910304323456744326056421227644920216556161710045794909005682363208754600486590889788250260509713591684353378394987140492585724853790406456014075678089228508113/3018');
is(bernfrac(503), '0');
is(bernfrac(504), '-1800677132945039166830463177507754585266379503826991151092966034031576449133878587142596465305242073160144152559961898077078097501165163926688621532562053786332313051581764169357553522652874187792692396402130149762806987993277139084391032030046378044998249662099092714127575238051587028714174701755384004616631602375127554782384747315933204589349029147149516932515107635948095098164610210913536208041544450420100527704419751371323572700724631061364176730785513373102292249369445493318934314234224568935547305550656813935645001939035328053977546993164816506035208503720862965294463401376513971725070845847755610266543649189247439588435678329734616774448010477321232208947899575788038500962386042680131078463676696610992661373557922895517318715229936758650701/22187634681030');
#>>>

#<<<
is(bernfrac(516), '-3171063754130662024524418208962167067839045665148673268688919788201122137993583170971808364662074274232666642053133416092689792604211548622761248164434705090369709712064325733752984791992995166295609910020711239553079790654718521438346662873716045934093264127240248286977372996484267736259265008438815998984993336599316663270012023125012925214851790655351808172000672749838840693509655263266601401037528301896401650239914332804014938251599783809089361608341378084286920983943097636310860163773870739980391209823884437560448434440200611799173871557105368827962979286668722271636912267960931855169772297597292043759562073364001053592129443037821577438519092603891356839904444624214933377703308448877887265978135387594080421289664078487170109243854104577168788777527205195143/472290');
is(bernfrac(517), '0');
is(bernfrac(518), '273280120135903400796020253856496684011788906317364748953085333993961201260103100240458401853886188153815729448551782636694969615369921631309790968386191316441784908017981662481469984984167042448669367248157448891503875887451536439734237831153280451449416018604604766043854195342721279546881034771821254740522985524013298494222843478038262936400568637590829723962229916157673134572264808025853029183736196477170743136876861347086019061648771011440314259278873592910071332879887012089047348037711009115437776321582669271597906200622918591149153504310087714501499195741647501615811271701261514080038678771942746736185575324689976357305256911162281729889368248612935815145764264376288803018064102298711008322925121890227372020995066241641153616485840062558888315856481206999/6');
#>>>

is(harmfrac(-2),          'NaN');
is(harmfrac(-1),          'NaN');
is(harmfrac(0),           '0');
is(harmfrac(1),           '1');
is(harmfrac(10),          '7381/2520');
is(harmfrac($o->new(10)), '7381/2520');

is(valuation(14,           0),          0);
is(valuation(64,           2),          6);
is(valuation($o->new(128), 2),          7);
is(valuation(128,          $o->new(2)), 7);
is(valuation($o->new(128), $o->new(2)), 7);

is(remdiv(64 * 3 * 3,   3),          64);
is(remdiv(12,           0),          12);
is(remdiv(37,           5),          37);
is(remdiv($o->new(576), 3),          64);
is(remdiv(576,          $o->new(3)), 64);
is(remdiv($o->new(576), $o->new(3)), 64);
is(remdiv(1,            1),          1);    # see: https://github.com/trizen/Math-AnyNum/issues/1#issuecomment-292738550
is(remdiv(0,            0),          0);

is(iadd(3,          4),           7);
is(iadd(-3,         -4),          -7);
is(iadd($o->new(3), 4),           7);
is(iadd($o->new(3), -4),          -1);
is(iadd($o->new(3), $o->new(-4)), -1);
is(iadd(3,          $o->new(-4)), -1);

is(isub(13,           3),           10);
is(isub(13,           -3),          16);
is(isub($o->new(13),  -3),          16);
is(isub(-13,          -3),          -10);
is(isub(-13,          $o->new(-3)), -10);
is(isub($o->new(-13), $o->new(-3)), -10);

is(imul(13,          2),           26);
is(imul(13,          -2),          -26);
is(imul(-13,         -2),          26);
is(imul($o->new(13), 2),           26);
is(imul($o->new(13), -2),          -26);
is(imul($o->new(13), $o->new(-2)), -26);
is(imul(13,          $o->new(-2)), -26);

is(idiv(1234,           10),           123);
is(idiv(1234,           -10),          -123);
is(idiv(-1234,          10),           -123);
is(idiv($o->new(1234),  -10),          -123);
is(idiv($o->new(-1234), 10),           -123);
is(idiv($o->new(-1234), $o->new(10)),  -123);
is(idiv(1234,           $o->new(-10)), -123);

is(imod(1234,           10),           4);
is(imod(1234,           -10),          -6);
is(imod(-1234,          -10),          -4);
is(imod($o->new(1234),  -10),          -6);
is(imod($o->new(-1234), -10),          -4);
is(imod($o->new(-1234), $o->new(-10)), -4);
is(imod($o->new(1234),  10),           4);

is(iroot(1234,           10),         2);
is(iroot(12345,          9),          2);
is(iroot(12345,          $o->new(9)), 2);
is(iroot($o->new(12345), 9),          2);
is(iroot($o->new(12345), $o->new(9)), 2);
is(iroot(-1,             2),          'NaN');
is(iroot(-2,             2),          'NaN');
is(iroot(1,              1),          1);
is(iroot(1,              2),          1);
is(iroot(-1,             1),          -1);
is(iroot(-2,             1),          -2);

is(icbrt(125),          5);
is(icbrt($o->new(125)), 5);
is(icbrt(-125),         -5);

is(isqrt(100),               10);
is(isqrt(987654),            993);
is(isqrt($o->new('987654')), 993);
is(isqrt(-1),                'NaN');
is(isqrt(-2),                'NaN');
is(isqrt(0),                 0);

is(icbrt(125),   5);
is(icbrt(1234),  10);
is(icbrt(-1234), -10);
is(icbrt(1),     1);
is(icbrt(0),     0);
is(icbrt(-1),    -1);

is(ilog(1234),   7);
is(ilog(123456), 11);
is(ilog(10000,          $o->new(10)), 4);
is(ilog(10000,          10),          4);
is(ilog($o->new(10000), 10),          4);
is(ilog($o->new('123456')), 11);
is(ilog(-1),                'NaN');

is(ilog(63,   2), '5');
is(ilog(64,   2), '6');
is(ilog(1023, 2), '9');
is(ilog(1024, 2), '10');

is(ilog(0, 42), 'NaN');
is(ilog(1, 42), '0');
is(ilog(2, 42), '0');

is(ilog(ipow(3, 60), 3), 60);
is(ilog(ipow(3, 61), 3), 61);
is(ilog(ipow(3, 62), 3), 62);

is(ilog2(64),             6);
is(ilog10(1000),          3);
is(ilog2($o->new(12345)), 13);
is(ilog10($o->new(999)),  2);
is(ilog2(-1),             'NaN');
is(ilog10(-1),            'NaN');

is((ipow(10, 64) - 1)->ilog(10), '63');
is((ipow(10, 64) + 0)->ilog(10), '64');
is((ipow(10, 64) + 1)->ilog(10), '64');

is(ilog(1,   0),  'NaN');    # ilog() does not handle bases < 2
is(ilog(0,   0),  'NaN');
is(ilog(0,   1),  'NaN');
is(ilog(1,   1),  'NaN');
is(ilog(1,   2),  '0');
is(ilog(2,   2),  '1');
is(ilog(2,   3),  '0');
is(ilog(3,   4),  '0');
is(ilog(2,   4),  '0');
is(ilog(4,   2),  '2');
is(ilog(63,  2),  '5');
is(ilog(64,  2),  '6');
is(ilog(64,  3),  '3');
is(ilog(81,  3),  '4');
is(ilog(80,  3),  '3');
is(ilog(64,  1),  'NaN');
is(ilog(-64, 2),  'NaN');
is(ilog(42,  -3), 'NaN');
is(ilog(-42, 3),  'NaN');

is(ilog(ipow(2,   100),     100), '15');
is(ilog(ipow(100, 100),     100), '100');
is(ilog(ipow(100, 100) - 1, 100), '99');
is(ilog(ipow(100, 100) + 1, 100), '100');

is(ilog(ipow(2, 100),     ipow(2, 100)), '1');
is(ilog(ipow(2, 100) - 1, ipow(2, 100)), '0');
is(ilog(ipow(2, 100),     ipow(2, 99)),  '1');

is(join(' ', isqrtrem(1234)), '35 9');
is(join(' ', isqrtrem(100)),  '10 0');
is(join(' ', irootrem(1234,     2)), '35 9');
is(join(' ', irootrem(1234,     5)), '4 210');
is(join(' ', irootrem(1234,     1)), '1234 0');
is(join(' ', irootrem('279841', 4)), '23 0');

is(powmod(123,          456,          19),          11);
is(powmod($o->new(123), 456,          19),          11);
is(powmod($o->new(123), $o->new(456), 19),          11);
is(powmod($o->new(123), $o->new(456), $o->new(19)), 11);
is(powmod(123,          $o->new(456), $o->new(19)), 11);
is(powmod(123,          $o->new(456), 19),          11);
is(powmod(123,          456,          $o->new(19)), 11);

is(powmod(123, -1, 17), 13);
is(powmod(123, -2, 17), 16);
is(powmod(123, -3, 17), 4);
is(powmod(123, -1, 15), 'NaN');
is(powmod(123, -2, 15), 'NaN');
is(powmod(123, -3, 15), 'NaN');

is(invmod(123,          17),          13);
is(invmod(123,          15),          'NaN');
is(invmod($o->new(123), 17),          13);
is(invmod($o->new(123), $o->new(17)), 13);
is(invmod(123,          $o->new(17)), 13);
is(invmod($o->new(123), 15),          'NaN');
is(invmod($o->new(123), $o->new(15)), 'NaN');

is(join(' ', grep { is_polygonal($_, 3) } -5 .. 36),    '0 1 3 6 10 15 21 28 36');
is(join(' ', grep { is_polygonal($_, 4) } -5 .. 36),    '0 1 4 9 16 25 36');
is(join(' ', grep { is_polygonal($_, 10) } -30 .. 100), '0 1 10 27 52 85');

#<<<
ok( is_polygonal('7005421398857629823126044593025618425102587271439458285811113043336554134634496', 123));
ok(!is_polygonal('7005421398857629823126044593025618425102587271439458285811113043336554134634495', 123));
ok(!is_polygonal('7005421398857629823126044593025618425102587271439458285811113043336554134634496', 122));
ok(!is_polygonal('7005421398857629823126044593025618425102587271439458285811113043336554134634496', 124));
#>>>

#<<<
ok( is_polygonal('682605052374967594330614766854850860622749872985299345595316675303735029870791433428787331293147139140057094398321784143216117285300207616', ipow(3, 128)));
ok(!is_polygonal('682605052374967594330614766854850860622749872985299345595316675303735029870791433428787331293147139140057094398321784143216117285300207616', ipow(3, 128) + 1));
#>>>

#<<<
ok(is_polygonal('3599999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999937', ipow(10, 128)));
#>>>

is(polygonal(10, 3), '55');
is(polygonal(12, Math::AnyNum->new(4)), '144');

is(join('', map { is_polygonal2($_, 5) ? 1 : 0 } qw(0 2 7 15 26 40 57 77 100)),   '1' x 9);
is(join('', map { is_polygonal2($_, 6) ? 1 : 0 } qw(0 3 10 21 36 55 78 105 136)), '1' x 9);

is(join(' ', map { ipolygonal_root2($_, 5) } qw(0 2 7 15 26 40 57 77 100)), '0 -1 -2 -3 -4 -5 -6 -7 -8');

ok(!is_polygonal2(1234, 5));
ok(!is_polygonal2(1234, 6));

#<<<
is(join(' ', map {

    my $n = $_;
    my $k = int(rand(1000000000)) + 3;

    ipolygonal_root(polygonal($n, $k), $k);

} 0..10), join(' ', 0..10));
#>>>

#<<<
is(join(' ', map {

    my $n = $_;
    my $k = int(rand(1000000000)) + 3;

    ipolygonal_root2(polygonal($n, $k), $k);

} -10..0), join(' ', -10..0));
#>>>

#<<<
is(join('', map {

    my $n = int(rand(100));
    my $k = $_;

    !!(polygonal(ipolygonal_root($n, $k), $k) == $n) eq !!is_polygonal($n, $k)

} 0..20), '1' x 21);
#>>>

is(faulhaber_sum(10, 0), 10);
is(faulhaber_sum(10, 1), 55);
is(faulhaber_sum(10, 2), 385);

#<<<
is(faulhaber_sum(97,   20), '27930470253682554320726764539206479400753');
is(faulhaber_sum(1234, 13), '1363782530586069716227147685797600627310545');
is(faulhaber_sum(30,   80), '15824906698911682552620450221533100599157410235977820404994404262610329210567189683421455768203096083923986638110352399');
is(faulhaber_sum('36893488147419103232', 6), '13290765244262525999877070971093849105865118528347431876799549931828154109852970889789225381341531108777505296823405714971493113182289920');
#>>>

is(geometric_sum(3, 8), 585);
is(geometric_sum(8, 3), 9841);

is(geometric_sum(13, '1/2'),  '16383/8192');
is(geometric_sum(12, '-1/2'), '2731/4096');
is(geometric_sum(17, '-1/2'), '87381/131072');
is(geometric_sum(15, '-4/3'), '-607417225/14348907');

ok(is_power('279841'), '23^4');
ok(is_power(100, 2),  '10^2');
ok(is_power(125, 3),  '5^3');
ok(is_power(1,   13), '1^x');
ok(is_power(-1,  3),  '(-1)^odd');
ok(!is_power(-1,   2), '(-1)^even');
ok(!is_power(-123, 5), '-123');
ok(!is_power(0,    0), '0^0');
ok(is_power(0, 1), '0^1');
ok(is_power(0, 2), '0^2');
ok(is_power(0, 3), '0^3');
ok(is_power(1),   'is_power(1)');
ok(is_power(-1),  'is_power(-1)');
ok(!is_power(-2), 'is_power(-2)');
ok(is_power(0),   'is_power(0)');

ok(is_square(100), 'is_square(100)');
ok(!is_square(99), 'is_square(99)');
ok(!is_square(-1), 'is_square(-1)');
ok(is_square(1),   'is_square(-1)');
ok(is_square(0),   'is_square(0)');

ok(is_prime(2),   '2 is prime');
ok(!is_prime(1),  '1 is not prime');
ok(!is_prime(0),  '0 is not prime');
ok(!is_prime(-1), '-1 is not prime');
ok(!is_prime(-2), '-2 is not prime');
ok(!is_prime(-3), '-3 is not prime');

ok(is_prime('165001'),          'is_prime');
ok(is_prime($o->new('165001')), 'is_prime');
ok(is_prime($o->new('165001'), 30), 'is_prime');
ok(!is_prime('113822804831'), '!is_prime');
ok(!is_prime('113822804831',          30),          '!is_prime');
ok(!is_prime($o->new('113822804831'), $o->new(30)), '!is_prime');
ok(!is_prime('1396981702787004809899378463251'), '!is_prime');

#ok(is_smooth(0,                      0));
#ok(is_smooth(0,                      40));
#ok(is_smooth(0,                      Math::AnyNum->new(40)));

ok(is_smooth(1,                      1));
ok(is_smooth(2,                      30));
ok(is_smooth(Math::AnyNum->new(1),   Math::AnyNum->new(1)));
ok(is_smooth(Math::AnyNum->new(1),   20));
ok(is_smooth(Math::AnyNum->new(2),   20));
ok(is_smooth(36,                     3));
ok(is_smooth(36,                     Math::AnyNum->new(3)));
ok(is_smooth(Math::AnyNum->new(125), Math::AnyNum->new(28)));
ok(is_smooth(13 * 13 * 13 * 3 * 2,   13));
ok(is_smooth(19 * 19 * 13 * 13,      19));

ok(is_smooth_over_prod(1,                    1));
ok(is_smooth_over_prod(1,                    Math::AnyNum->new(1)));
ok(is_smooth_over_prod(Math::AnyNum->new(1), Math::AnyNum->new(1)));
ok(is_smooth_over_prod(Math::AnyNum->new(1), 1));
ok(is_smooth_over_prod(2,                    30));
ok(is_smooth_over_prod(19 * 19 * 13 * 13,    19 * 13 * 13 * 5));
ok(is_smooth_over_prod(13 * 13 * 13 * 3 * 2, 13 * 3 * 2 * 19));

ok(!is_smooth_over_prod(13 * 13 * 13 * 3 * 2, 13));
ok(!is_smooth_over_prod(19 * 19 * 13 * 13,    19));

#ok(is_smooth(-125,                   5));
#ok(is_smooth(-125,                   -5));
#ok(is_smooth(125 * 3,                -5));

is(join(' ', grep { is_smooth($_, 3) } 0 .. 30), '1 2 3 4 6 8 9 12 16 18 24 27');
is(join(' ', grep { is_smooth_over_prod($_, 3 * 5 * 7 * 11) } 0 .. 30), '1 3 5 7 9 11 15 21 25 27');

ok(!is_smooth(13 * 5 * 7,                 11));
ok(!is_smooth(-13 * 5,                    11));
ok(!is_smooth(-13 * 5,                    -11));
ok(!is_smooth(Math::AnyNum->new(-13 * 5), Math::AnyNum->new(-11)));
ok(!is_smooth(13 * 5,                     -11));
ok(!is_smooth(13 * 5,                     Math::AnyNum->new(-11)));
ok(!is_smooth(13 * 5 * 7,                 Math::AnyNum->new(12)));
ok(!is_smooth(39,                         6));
ok(!is_smooth(1,                          0));
ok(!is_smooth(2,                          1));
ok(!is_smooth(2,                          Math::AnyNum->new(1)));
ok(!is_smooth(1,                          Math::AnyNum->new(0)));

ok(!is_smooth_over_prod(-13 * 5,                               11));
ok(!is_smooth_over_prod(-13 * 5,                               -11));
ok(!is_smooth_over_prod(Math::AnyNum->new(13 * 5 * 7 * 8 * 3), 12));
ok(!is_smooth_over_prod(Math::AnyNum->new(2),                  Math::AnyNum->new(1)));
ok(!is_smooth_over_prod(1,                                     Math::AnyNum->new(0)));

is(next_prime(-10),               '2');
is(next_prime('165001'),          '165037');
is(next_prime($o->new('165001')), '165037');

is_deeply(
    [map { subfactorial($_) } 0 .. 23],
    [qw(
       1 0 1 2 9 44 265 1854 14833 133496 1334961 14684570 176214841 2290792932
       32071101049 481066515734 7697064251745 130850092279664 2355301661033953
       44750731559645106 895014631192902121 18795307255050944540 413496759611120779881
       9510425471055777937262
       )
    ],
    "subfactoral(n) for n=0..23"
         );

is_deeply([map { subfactorial(7, $_) } 0 .. 7], [qw(1854 1855 924 315 70 21 0 1)], "subfactorial(7, n) for n=0..7");

is(subfactorial(Math::AnyNum->new(7), Math::AnyNum->new(5)), 21);
is(subfactorial(Math::AnyNum->new(7), 5),                    21);
is(subfactorial(7,                    Math::AnyNum->new(5)), 21);

is(subfactorial(-20, -20), 'NaN');
is(subfactorial(12,  20),  'NaN');
is(subfactorial(-12), 'NaN');
is(subfactorial(0,  0),   1);
is(subfactorial(0,  -1),  0);
is(subfactorial(0,  -20), 0);
is(subfactorial(30, -20), 0);

is(multinomial(3, 17, 9), '11417105700');
is(multinomial(7, 2, 5, 2, 12, 11), '440981754363423854380800');
is(multinomial(Math::AnyNum->new(7), 2, 5, Math::AnyNum->new(2), 12, Math::AnyNum->new(11)), '440981754363423854380800');
