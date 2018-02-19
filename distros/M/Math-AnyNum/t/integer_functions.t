#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 402;    # be careful

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

is(factorial(0),          '1');
is(factorial(5),          '120');
is(factorial(-1),         'NaN');
is(factorial($o->new(5)), '120');

is(fibonacci(0),           '0');
is(fibonacci(12),          '144');
is(fibonacci(-3),          'NaN');
is(fibonacci($o->new(12)), '144');

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

is(lcm(13,          14),          182);
is(lcm(14,          $o->new(13)), 182);
is(lcm($o->new(14), 13),          182);
is(lcm($o->new(13), $o->new(14)), 182);

is(lcm($o->new(42), "1210923789812382173912783"), '7265542738874293043476698');
is(lcm(42,          "1210923789812382173912783"), '7265542738874293043476698');

is(lcm(12, -28),          84);
is(lcm(12, $o->new(-28)), 84);

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

is(gcd(20,          12),          4);
is(gcd($o->new(20), 12),          4);
is(gcd(20,          $o->new(12)), 4);
is(gcd($o->new(12), $o->new(20)), 4);

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

ok(is_prime('165001'),          'is_prime');
ok(is_prime($o->new('165001')), 'is_prime');
ok(is_prime($o->new('165001'), 30), 'is_prime');
ok(!is_prime('113822804831'), '!is_prime');
ok(!is_prime('113822804831',          30),          '!is_prime');
ok(!is_prime($o->new('113822804831'), $o->new(30)), '!is_prime');

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

#ok(is_smooth(-125,                   5));
#ok(is_smooth(-125,                   -5));
#ok(is_smooth(125 * 3,                -5));

is(join(' ', grep { is_smooth($_, 3) } 0 .. 30), '1 2 3 4 6 8 9 12 16 18 24 27');

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
