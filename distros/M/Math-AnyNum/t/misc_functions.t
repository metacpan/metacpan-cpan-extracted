#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 597;

use Math::AnyNum qw(:misc lngamma ipow10 log);
use List::Util qw();

my $o = 'Math::AnyNum';

is(rand(0), 0);
ok(rand(1) < 1,     'rand(1) < 1');
ok(rand(0.2) < 0.2, 'rand(0.2) < 0.2');

ok(rand(0, 2) < 2,       'rand(2) < 2');
ok(rand(0, 1000) < 1000, 'rand(0, 1000) < 1000');

ok(rand(123, 130) >= 123);
ok(rand(123, 130) < 130);

is(irand(0), 0);
ok(irand(1) <= 1,      'irand(1) <= 1');
ok(irand(1, 10) <= 10, 'irand(1, 10) <= 10');

is(irand(10,  10),  10);
is(irand(0,   0),   0);
is(irand(-10, -10), -10);
is(irand(1,   1),   1);

{
    my $rand = rand(1000, 1100);
    ok($rand >= 1000);
    ok($rand < 1100);
}

{
    my $rand = rand(10.5, 10.6);
    ok($rand >= 10.5);
    ok($rand < 10.6);
}

{
    my $irand = irand(1000, 1100);
    ok($irand >= 1000);
    ok($irand <= 1100);
}

my $beg_inclusive = 0;
foreach my $i (1 .. 1000) {
    if (irand(10, 11) == 10) {
        $beg_inclusive = 1;
        last;
    }
}
ok($beg_inclusive, 'rand is beg-inclusive');

my $end_inclusive = 0;
foreach my $i (1 .. 1000) {
    if (irand(10, 11) == 11) {
        $end_inclusive = 1;
        last;
    }
}
ok($end_inclusive, 'rand is end-inclusive');

ok(!defined(min()));
ok(!defined(max()));

is(max(0), 0);
is(min(0), 0);

is(max(5, 2), '5');
is(min(2, 5), '2');

is(max(2, 5), '5');
is(min(5, 2), '2');

is(max(3, 5, 2), 5);
is(min(3, 1, 2), 1);

is(max('-43/9', '-19/2', '-9', '-3.4', '-3-10i', '-4'),     '-3-10i');
is(min('43/9', '-19/2', 42, '-9', '-3.4', '-3-10i', '9.1'), '-19/2');

ok(!defined(max(5, 'NaN', 42)));
ok(!defined(min(5, 'NaN', 42)));

is(sum(),  0);
is(prod(), 1);

is(sum(3, 5, 9, 41),  3 + 5 + 9 + 41);
is(prod(3, 5, 9, 41), 3 * 5 * 9 * 41);

is(sum(3, 5, "4/3", 9, "17/19", 11, "11/5"),  "9242/285");
is(prod(3, 5, "4/3", 9, "17/19", 11, "11/5"), "74052/19");

is(float(3.14159),         '3.14159');
is(float('777/222'),       '3.5');
is(float('123+45i'),       '123+45i');
is(float('3.1+4.2i'),      '3.1+4.2i');
is(float(sqrt(float(-1))), 'i');

is(sgn(-3), -1);
is(sgn(0),  0);
is(sgn(13), +1);

is(sgn(int(-3)), -1);
is(sgn(int(0)),  0);
is(sgn(int(13)), +1);

is(sgn(float(-3.5)),  -1);
is(sgn(float(0)),     0);
is(sgn(float(13.12)), +1);

is(sgn(rat('-3/4')), -1);
is(sgn(rat(0)),      0);
is(sgn(rat('13/2')), +1);

is(sgn(complex(-3)),     -1);
is(sgn(complex(0)),      0);
is(sgn(complex(13)),     +1);
is(sgn(complex('3+4i')), '0.6+0.8i');

is(popcount(123),           6);
is(popcount($o->new(-123)), 6);
is(popcount(16),            1);
is(popcount(-16),           1);

is(hamdist(412,          123),          7);
is(hamdist($o->new(412), 413),          1);
is(hamdist(414,          $o->new(314)), 3);
is(hamdist($o->new(213), $o->new(321)), 4);

is(bit_scan0(1915), 2);
is(bit_scan0(1915,          5),          7);
is(bit_scan0($o->new(1915), 3),          7);
is(bit_scan0($o->new(1915), $o->new(4)), 7);

is(bit_scan1(580), 2);
is(bit_scan1(580,          3),          6);
is(bit_scan1($o->new(580), 3),          6);
is(bit_scan1(580,          $o->new(4)), 6);
is(bit_scan1($o->new(580), $o->new(3)), 6);

is(join(' ', reals('3-4i')),           "3 -4");
is(join(' ', reals(complex('-3-4i'))), "-3 -4");
is(join(' ', reals(float("42"))),      '42 0');
is(join(' ', reals("42i")),            '0 42');
is(join(' ', reals("-42i")),           '0 -42');
is(join(' ', reals("-13-42i")),        '-13 -42');

is(join(' ', nude('3/4')),      '3 4');
is(join(' ', nude('-3/4')),     '-3 4');
is(join(' ', nude('-3/-4')),    '3 4');
is(join(' ', nude('3/-4')),     '-3 4');
is(join(' ', nude(rat('3/4'))), '3 4');
is(join(' ', nude('42')),       '42 1');
is(join(' ', nude('-42')),      '-42 1');

is(neg('3'),        '-3');
is(neg('3+4i'),     '-3-4i');
is(neg(rat('3/4')), '-3/4');

is(conj('3+4i'),           '3-4i');
is(conj(complex('-3-4i')), '-3+4i');
is(conj('4'),              '4');
is(conj(rat('-3')),        '-3');
is(conj('3/4'),            '3/4');

is(inv('3/4'),      '4/3');
is(inv(rat('3/4')), '4/3');
is(inv('42'),       '1/42');
is(inv('-42'),      '-1/42');
is(inv('0'),        'Inf');
is(inv('-1'),       '-1');

is(ref(${Math::AnyNum->new('0')}), 'Math::GMPz');

is(real(complex('3+4i')), '3');
is(real('12.34'),         '12.34');
is(real(rat('3/4')),      '3/4');
is(real(int('-42')),      '-42');
is(real(float('-1.2')),   '-1.2');
is(real('3+4i'),          '3');
is(real('4i'),            '0');
is(real(complex('4i')),   '0');
is(real("42"),            '42');

is(imag(complex('3+4i')), '4');
is(imag('12.34'),         '0');
is(imag(rat('3/4')),      '0');
is(imag(int('-42')),      '0');
is(imag(float('-1.2')),   '0');
is(imag('3+4i'),          '4');
is(imag('4i'),            '4');
is(imag(complex('4i')),   '4');
is(imag("42"),            '0');

is(round('123499999/100000',  0), '1235');
is(round('-123499999/100000', 0), '-1235');

is(round('1234567/1000'),  '1235');     #  1234.567 ->  1235
is(round('-1234567/1000'), '-1235');    # -1234.567 -> -1235

is(round('6170617/5000'),  '1234');     #  1234.1234 ->  1234
is(round('-6170617/5000'), '-1234');    # -1234.1234 -> -1234

is(round('6170617/5000',  -2), '30853/25');     #  1234.1234 ->  1234.12
is(round('-6170617/5000', -2), '-30853/25');    # -1234.1234 -> -1234.12

is(round('3086219/2500', -3), '154311/125');    # 1234.4876 -> 1234.488

is(round('123456', 2), '123500');
is(round('123456', 3), '123000');
is(round('123456', 0), '123456');

is(round('-123456', 2), '-123500');
is(round('-123456', 3), '-123000');

is(numerator('3/4'),          '3');
is(numerator('123/567'),      '41');            # simplifies to '41/189'
is(numerator(int(42)),        '42');
is(numerator(rat('123/567')), '41');            # simplifies to '41/189'

is(numerator(float('12')),     '12');
is(numerator(float('0.75')),   '3');            # '3/4'
is(numerator(complex('12')),   '12');
is(numerator(complex('0.75')), '3');            # '3/4'
is(numerator('0.75'),          '3');            # '3/4'
is(numerator(complex('3+4i')), 'NaN');
is(numerator("-42"),           "-42");

is(denominator('3/4'),          '4');
is(denominator('123/567'),      '189');         # simplifies to '41/189'
is(denominator(int(42)),        '1');
is(denominator(rat('123/567')), '189');         # simplifies to '41/189'

is(denominator(float('12')),     '1');
is(denominator(float('0.75')),   '4');          # '3/4'
is(denominator(complex('12')),   '1');
is(denominator(complex('0.75')), '4');          # '3/4'
is(denominator('0.75'),          '4');          # '3/4'
is(denominator(complex('3+4i')), 'NaN');
is(denominator("-42"),           "1");

is($o->new('87524175757784805286500803841234030417952156390545')->length, 50);
is($o->new('534303892')->length(2),                                       29);
is($o->new('7583819')->length(3),                                         15);
is($o->new('4258784685')->length(4),                                      16);
is($o->new('5040')->length(5),                                            6);
is($o->new('5040')->length,                                               4);

is(join(' ', digits('1234')),      '4 3 2 1');
is(join(' ', digits('1234.5678')), '4 3 2 1');    # only the integer part is considered
is(join(' ', digits('-1234')),     '4 3 2 1');

is(join(' ', digits('1234',           16)),          '2 13 4');
is(join(' ', digits($o->new('1234'),  16)),          '2 13 4');
is(join(' ', digits($o->new('1234'),  $o->new(16))), '2 13 4');
is(join(' ', digits('1234',           $o->new(7))),  '2 1 4 3');
is(join(' ', digits('-1234',          $o->new(9))),  '1 2 6 1');
is(join(' ', digits($o->new('-1234'), $o->new(4))),  '2 0 1 3 0 1');
is(join(' ', digits($o->new('-1234'), 36)),          '10 34');
is(join(' ', digits('-1234',          2)),           '0 1 0 0 1 0 1 1 0 0 1');
is(join(' ', digits('12345',          100)),         '45 23 1');

is(join(' ', digits('3735928559', 16)), '15 14 14 11 13 10 14 13');
is(join(' ', digits('3735928559', 17)), '8 7 16 6 3 13 1 9');
is(join(' ', digits('3735928559', 9)),  '2 7 4 4 2 7 0 7 5 0 1');
is(join(' ', digits('3735928559', 11)), '0 7 4 10 1 9 7 4 6 1');

is(join(' ', digits('62748517',                       '2744')),                 '1469 915 8');
is(join(' ', digits('27875458237207974418',           '4728933560')),           '365843178 1165727019 1');
is(join(' ', digits('996105818874172862495850884533', '81592785159219522212')), '40776745621457483269 12208258572');

is(join(' ', digits(1234, -12)), '');    # not defined for negative bases
is(join(' ', digits(1234, -92)), '');    # not defined for negative bases
is(join(' ', digits(1234, 1)),   '');    # not defined for bases <= 1
is(join(' ', digits(1234, 0)),   '');

#is(digits2num([5040, 1234], 10), 1234*10 + 5040);      # currenlty this is not supported

is(digits2num([], -1),           'NaN');
is(digits2num([1, 2, 3, 4], -1), 'NaN');
is(digits2num([]),               0);
is(digits2num([], 100),          0);
is(digits2num([5, 4, 3, 2, 1]),  12345);
is(digits2num([45, 23, 1], 100), 12345);
is(digits2num([digits('996105818874172862495850884533', '81592785159219522212')], '81592785159219522212'),
    '996105818874172862495850884533');

is(sumdigits(1234, -12), 'NaN');
is(sumdigits(1234, -75), 'NaN');
is(sumdigits(1234, 1),   'NaN');
is(sumdigits(1234, 0),   'NaN');

is(sumdigits('1234.5678'), 4 + 3 + 2 + 1);    # only the integer part is considered
is(sumdigits('-1234',                          $o->new(9)),             1 + 2 + 6 + 1);
is(sumdigits($o->new('-1234'),                 36),                     10 + 34);
is(sumdigits('-1234',                          9),                      1 + 2 + 6 + 1);
is(sumdigits('62748517',                       $o->new('2744')),        '2392');
is(sumdigits($o->new('62748517'),              $o->new('2744')),        '2392');
is(sumdigits('996105818874172862495850884533', '81592785159219522212'), '40776745633665741841');

is(sumdigits('686826004874792510055462773868368874990',                37),          '414');
is(sumdigits('66584215709534655468641985856223026563233736779476',     38),          '572');
is(sumdigits('777167811371535604138338540903539713319011224805',       46),          '730');
is(sumdigits('613136010035433834160054719450842585569017976622615403', 45),          '751');
is(sumdigits('505738355663143406692565836710328900161705022531597459', 54),          '846');
is(sumdigits('8704872396456046071051264811294183381856891',            $o->new(42)), '517');

is(List::Util::sum(digits('686826004874792510055462773868368874990',                37)),          '414');
is(List::Util::sum(digits('66584215709534655468641985856223026563233736779476',     38)),          '572');
is(List::Util::sum(digits('777167811371535604138338540903539713319011224805',       46)),          '730');
is(List::Util::sum(digits('613136010035433834160054719450842585569017976622615403', 45)),          '751');
is(List::Util::sum(digits('505738355663143406692565836710328900161705022531597459', 54)),          '846');
is(List::Util::sum(digits('8704872396456046071051264811294183381856891',            $o->new(42))), '517');

is(
    bsearch(
        100, 120,
        sub {
            $_**2 <=> 12769;
        }
    ),
    113
  );

is(bsearch_le(10**6, sub { exp($_) <=> 1e+9 }), 20);             #=>  20   (exp( 20) <= 1e+9)
is(bsearch_le(-10**6, 10**6, sub { exp($_) <=> 1e-9 }), -21);    #=> -21   (exp(-21) <= 1e-9)

is(bsearch_ge(10**6, sub { exp($_) <=> 1e+9 }), 21);             #=>  21   (exp( 21) >= 1e+9)
is(bsearch_ge(-10**6, 10**6, sub { exp($_) <=> 1e-9 }), -20);    #=> -20   (exp(-20) >= 1e-9)

is(
    bsearch(
        100, 120,
        sub {
            my ($n) = @_;
            $n * $n <=> 12769;
        }
    ),
    113
  );

is(
    bsearch(
        100,
        sub {
            $_ * $_ <=> 49;
        }
    ),
    7
  );

is(
    bsearch_le(
        5,
        10**6,
        sub {
            my ($n) = @_;
            $n <=> int(exp(12));
        }
    ),
    '162754'
  );

is(
    bsearch_ge(
        5,
        10**6,
        sub {
            my ($n) = @_;
            $n <=> int(exp(12));
        }
    ),
    '162754'
  );

sub largest_factorial_lt {
    my ($n) = @_;

    my $t = $n * log(10);
    bsearch_le(
        $n,
        sub {
            lngamma($_ + 1) <=> $t;
        }
    );
}

is(largest_factorial_lt(10**6),      '205022');
is(largest_factorial_lt(ipow10(21)), '51865645374019695121');

sub largest_factorial_gt {
    my ($n) = @_;

    my $t = $n * log(10);
    bsearch_ge(
        $n,
        sub {
            lngamma($_ + 1) <=> $t;
        }
    );
}

is(largest_factorial_gt(10**6),      '205023');
is(largest_factorial_gt(ipow10(21)), '51865645374019695122');

sub factorial_power_1 {
    my ($n, $p) = @_;
    ($n - sumdigits($n, $p)) / ($p - 1);
}

sub factorial_power_2 {
    my ($n, $p) = @_;
    my $sum = 0;
    $sum += $_ for digits($n, $p);
    ($n - $sum) / ($p - 1);
}

my $n = Math::AnyNum->new(100);
my $f = $n->factorial;

my @primes = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97);

{
    my $prod = 1;
    foreach my $p (@primes) {
        $prod *= Math::AnyNum::ipow($p, factorial_power_1($n, $p));
    }
    is($prod, $f);
}

{
    my $prod = 1;
    foreach my $p (@primes) {
        $prod *= Math::AnyNum::ipow($p, factorial_power_2($n, $p));
    }
    is($prod, $f);
}

{
    my $x = Math::AnyNum->new('1000', 2);
    my $y = Math::AnyNum->new('1001', 2);

    my $t = Math::AnyNum->new(2);
    my $z = Math::AnyNum->new(0);

    is(setbit(0b1000, 0), 0b1001);
    is(setbit(0b1000, 2), 0b1100);

    is(clearbit(0b1001, 0), 0b1000);
    is(clearbit(0b1100, 2), 0b1000);

    is(getbit(0b1001, 0), 1);
    is(getbit(0b1000, 0), 0);

    is(setbit($x,     0),  0b1001);
    is(setbit(0b1000, $t), 0b1100);
    is(setbit($x,     $t), 0b1100);

    is(flipbit(0b1000, 0),  0b1001);
    is(flipbit(0b1001, 0),  0b1000);
    is(flipbit($y,     3),  1);
    is(flipbit($y,     $t), 0b1101);

    is(clearbit($y,     0),  0b1000);
    is(clearbit(0b1100, $t), 0b1000);
    is(clearbit($y,     3),  $t - 1);

    is(getbit($y,     0),  1);
    is(getbit(0b1000, $z), 0);
}

is(as_bin(42), '101010');
is(as_oct(42), '52');
is(as_hex(42), '2a');

is(as_bin(complex(42)), '101010');
is(as_oct(rat(42)),     '52');
is(as_hex(float(42)),   '2a');

is(base('255',   16), 'ff');
is(base(rat(42), 8),  '52');

is(base(42,        2),  "101010");
is(base(17.5,      36), "h.i");
is(base("99/43",   16), "63/2b");
is(base("17.5+5i", 36), "(h.i 5)");

is(Math::AnyNum->new("101010",  2),  42);
is(Math::AnyNum->new("h.i",     36), "17.5");
is(Math::AnyNum->new("63/2b",   16), "99/43");
is(Math::AnyNum->new("(h.i 5)", 36), "17.5+5i");

is(Math::AnyNum->new(42)->base(2), '101010');
is(Math::AnyNum->new(base(float(42),   16), 16), '42');
is(Math::AnyNum->new(base(complex(42), 2),  2),  '42');

is(Math::AnyNum->new(Math::AnyNum->new("23.34375",   10)->base(2),  10), "10111.01011");
is(Math::AnyNum->new(Math::AnyNum->new("1011.11101", 10)->base(10), 2),  "11.90625");

sub dec2bin {
    my ($n) = @_;
    Math::AnyNum->new($n->base(2), 10);
}

sub bin2dec {
    my ($n) = @_;
    Math::AnyNum->new($n->base(10), 2);
}

is(dec2bin(rat("23.34375")),   rat("10111.01011"));
is(bin2dec(rat("1011.11101")), rat("11.90625"));

is(dec2bin(float("23.34375")),   float("10111.01011"));
is(bin2dec(float("1011.11101")), float("11.90625"));

is(dec2bin(complex("23.34375")),   complex("10111.01011"));
is(bin2dec(complex("1011.11101")), complex("11.90625"));

foreach my $t (Math::AnyNum::bernoulli(42),
               sqrt(float(2)), -sqrt(float(5)),
               complex(Math::AnyNum->pi, Math::AnyNum->e),
               -complex(sqrt(float(2)), log(float(2))),
               complex(0, sqrt(float(6))),
               complex(0, -sqrt(float(13))),
  ) {
    is(Math::AnyNum->new($t->base(2),  2),  $t);
    is(Math::AnyNum->new($t->base(10), 10), $t);
    is(Math::AnyNum->new($t->base(12), 12), $t);
    is(Math::AnyNum->new($t->base(33), 33), $t);
    is(Math::AnyNum->new($t->base(36), 36), $t);
}

is(Math::AnyNum->new(complex("23.34375")->base(2),    10), "10111.01011");
is(Math::AnyNum->new(complex("1011.11101")->base(10), 2),  "11.90625");

is(Math::AnyNum->new(sqrt(float(2))->base(34),                                      34), sqrt(float(2)));
is(Math::AnyNum->new((sqrt(float(2)) + sqrt(float(3)) * sqrt(float(-1)))->base(34), 34),
    sqrt(float(2)) + sqrt(float(3)) * sqrt(float(-1)));

is(as_int('255',          16), 'ff');
is(as_int(rat('255'),     16), 'ff');
is(as_int(float('255'),   16), 'ff');
is(as_int(complex('255'), 16), 'ff');

is(as_int('42.99',  10),        '42');
is(as_int('-42.99', "10.0001"), '-42');

is(as_int('12.5',  rat(16)),     'c');
is(as_int('-12.5', float(16)),   '-c');
is(as_int('-12.5', complex(16)), '-c');

ok(!defined(as_rat(complex(-1)->sqrt)));
ok(!defined(as_frac(complex(-1)->sqrt)));

is(as_rat('2/4'),   '1/2');
is(as_rat('42'),    '42');
is(as_rat(255, 16), "ff");

is(as_frac('123/567'), '41/189');
is(as_frac('42'),      '42/1');

is(rat_approx(complex('0.75')), '3/4');
is(rat_approx(float('0.75')),   '3/4');

is(as_frac('123/567',     16),          '29/bd');
is(as_frac(rat('43/255'), 16),          '2b/ff');
is(as_frac(rat('43/255'), complex(16)), '2b/ff');
is(as_frac(rat('0.75'),   rat(2)),      '11/100');

is(as_rat(complex(43), complex(5)), '133');
is(as_rat(rat('0.75'), rat(2)),     '11/100');

is(as_dec(sqrt(float(2)),   3), '1.41');
is(as_dec(sqrt(rat(2)),     4), '1.414');
is(as_dec(sqrt(complex(2)), 5), '1.4142');

is(as_dec('0.5'),          '0.5');
is(as_dec('0.5', 10),      '0.5');
is(as_dec(rat('0.5'), 10), '0.5');
is(as_dec(complex('0.5')), '0.5');

is(as_dec(complex('3+4i')), '3+4i');
is(as_dec(complex('3.142421+4.123213i'), rat(3)),     '3.14+4.12i');
is(as_dec(complex('3.142421+4.123213i'), complex(3)), '3.14+4.12i');

ok(is_pos(int(42)));
ok(is_pos(float('42.3')));
ok(is_pos(rat('12/7')));
ok(is_pos(complex('123.456')));

ok(!is_pos(int(-42)));
ok(!is_pos(float('-42.3')));
ok(!is_pos(rat('-12/7')));
ok(!is_pos(complex('-123.456')));

ok(is_neg(int(-42)));
ok(is_neg(float('-42.3')));
ok(is_neg(rat('-12/7')));
ok(is_neg(complex('-123.456')));

ok(!is_neg(int(42)));
ok(!is_neg(float('42.3')));
ok(!is_neg(rat('12/7')));
ok(!is_neg(complex('123.456')));

ok(is_mone(int(-1)));
ok(is_mone(rat('-1')));
ok(is_mone(float('-1')));
ok(is_mone(complex('-1')));

ok(!is_mone(int('1')));
ok(!is_mone(rat('1')));
ok(!is_mone(float('1')));
ok(!is_mone(complex('1')));

ok(is_one(int('1')));
ok(is_one(rat('1')));
ok(is_one(float('1')));
ok(is_one(complex('1')));

ok(!is_one(int(-1)));
ok(!is_one(rat('-1')));
ok(!is_one(float('-1')));
ok(!is_one(complex('-1')));

ok(is_zero(int(0)));
ok(is_zero(rat('0/1')));
ok(is_zero(float('0.000')));
ok(is_zero(complex('0.000+0.000i')));

ok(is_zero('0'));
ok(is_zero('0.000'));
ok(is_zero('0/1'));
ok(is_zero('0.000+0.000i'));

ok(!is_zero('0.001'));
ok(!is_zero(complex('0.001')));
ok(!is_zero(complex('0+0.01i')));
ok(!is_zero(complex('0-0.1i')));
ok(!is_zero(complex('0.1i')));
ok(!is_zero(complex('-0.1i')));

ok(is_even(int('42')));
ok(is_even(rat('42')));
ok(is_even(float('42')));
ok(is_even(complex('42')));

ok(!is_even(rat('42/5')));
ok(!is_even(float('42.5')));
ok(!is_even(complex('42.1')));
ok(!is_even(complex('42i')));    # this may change in the future

ok(is_zero(complex('42i') % 2));

is(int('17') % '3.4',          '0');
is(rat('17') % '17/5',         '0');
is(float('17') % float('3.4'), '0');
is(float('17') % '3.4',        '0');

is(rat('-1231241.12341'),     '-123124112341/100000');
is(rat('4231241.126486'),     '2115620563243/500000');
is(rat('-1.42e-13'),          '-71/500000000000000');
is(rat('-1.42e13'),           '-14200000000000');
is(rat('+1.42e+13'),          '14200000000000');
is(rat('12341.234_125e2'),    '98729873/80');
is(rat('12341.2_34_12_5e-2'), '98729873/800000');
is(rat('13e2'),               '1300');
is(rat('0.13e2'),             '13');
is(rat('0.013e2'),            '13/10');
is(rat('0.013e5'),            '1300');
is(rat('13e-2'),              '13/100');
is(rat('12.0000'),            '12');
is(rat('12.000e0'),           '12');
is(rat('12.000e4'),           '120000');
is(rat('1234.000e2'),         '123400');
is(rat('0.000e2'),            '0');
is(rat('0.000e12'),           '0');
is(rat('0.000e-12'),          '0');
is(rat('0.000e-0'),           '0');
is(rat('1234.000e-2'),        '617/50');
is(rat('1234.000e-5'),        '617/50000');
is(rat('-3.000e-7'),          '-3/10000000');
is(rat('-1234.000e-2'),       '-617/50');

is(rat('foo'),                     'NaN');
is(rat('3+4i'),                    'NaN');
is(rat(Math::AnyNum->new_c(3, 4)), 'NaN');

is(ratmod(413,              97),           25);
is(ratmod("43/97",          127),          79);
is(ratmod("43/97",          $o->new(127)), 79);
is(ratmod($o->new("43/97"), 127),          79);
is(ratmod($o->new("43/97"), $o->new(127)), 79);

ok(!(float(0) != '0'));
ok(!(complex(0) != '0'));
ok(!(rat(0) != '0'));
ok(!(int(0) != '0'));

ok(float(0) != '-1');
ok(complex(0) != '-1');
ok(rat(0) != '-1');
ok(int(0) != '-1');

ok(float(0) != '1');
ok(complex(0) != '1');
ok(rat(0) != '1');
ok(int(0) != '1');

ok(float(0) == '0');
ok(rat(0) == '0');
ok(int(0) == '0');
ok(complex(0) == '0');

ok(!(float(0) == '1'));
ok(!(rat(0) == '1'));
ok(!(int(0) == '1'));
ok(!(complex(0) == '1'));

ok(!(float(0) == '-1'));
ok(!(rat(0) == '-1'));
ok(!(int(0) == '-1'));
ok(!(complex(0) == '-1'));

is(float(0)   <=> '0', 0);
is(rat(0)     <=> '0', 0);
is(int(0)     <=> '0', 0);
is(complex(0) <=> '0', 0);

is(float(0)   <=> '1', -1);
is(rat(0)     <=> '1', -1);
is(int(0)     <=> '1', -1);
is(complex(0) <=> '1', -1);

is(float(0)   <=> '-1', 1);
is(rat(0)     <=> '-1', 1);
is(int(0)     <=> '-1', 1);
is(complex(0) <=> '-1', 1);

is(complex(3,       4),         '3+4i');
is(complex(-3,      -4),        '-3-4i');
is(complex('3+4i',  '12-3i'),   '6+16i');
is(complex('(3 4)', '(12 -3)'), '6+16i');

{
    my $p = Math::AnyNum->new(100);

    is($p + complex('-1/5',  '-1/2'), '99.8-0.5i');
    is($p + complex('+13',   '0.2'),  '113+0.2i');
    is($p + complex('3+4i',  '5-6i'), '109+9i');
    is($p + complex('-3+6i', '-0.5'), '97+5.5i');

    is($p + complex(Math::AnyNum->new('3+4i'), Math::AnyNum->new('5-6i')), '109+9i');
    is($p + complex(Math::AnyNum->new(13),     Math::AnyNum->new('+0.2')), '113+0.2i');
    is($p + complex(Math::AnyNum->new(13),     Math::AnyNum->new('1/2')),  '113+0.5i');
}

ok(is_odd(int('43')));
ok(is_odd(rat('43')));
ok(is_odd(float('43')));
ok(is_odd(complex('43')));

ok(!is_div(int('55'), 13));
ok(!is_div(int('55'), int('13')));

ok(!is_div(123, 11));
ok(!is_div(123, int(11)));

ok(is_div(int('42'),      int('3')));
ok(is_div(int('42'),      '2'));
ok(is_div('42',           '2'));
ok(is_div('4i',           '2'));
ok(is_div(complex('12i'), '3'));
ok(is_div('17',           '17/5'));
ok(is_div('17',           '3.4'));
ok(is_div('17',           complex('3.4')));
ok(is_div(float('17'),    complex('3.4')));
ok(is_div(rat('17'),      complex('3.4')));
ok(is_div(complex('17'),  complex('3.4')));

ok(!is_congruent(int('55'), 0, 13));
ok(!is_congruent(int('55'), 0, int('13')));

ok(!is_congruent(123, 0, 11));
ok(!is_congruent(123, 0, int(11)));

ok(is_congruent(int('42'),      0, int('3')));
ok(is_congruent(int('42'),      0, '2'));
ok(is_congruent('42',           0, '2'));
ok(is_congruent('4i',           0, '2'));
ok(is_congruent(complex('12i'), 0, '3'));
ok(is_congruent('17',           0, '17/5'));
ok(is_congruent('17',           0, '3.4'));
ok(is_congruent('17',           0, complex('3.4')));
ok(is_congruent(float('17'),    0, complex('3.4')));
ok(is_congruent(rat('17'),      0, complex('3.4')));
ok(is_congruent(complex('17'),  0, complex('3.4')));

ok(is_congruent(83, 3,  5));
ok(is_congruent(83, -2, 5));

ok(is_congruent(int(83),     3,  5));
ok(is_congruent(rat(83),     3,  5));
ok(is_congruent(complex(83), 3,  5));
ok(is_congruent(int(83),     -2, 5));
ok(is_congruent(complex(83), -2, 5));
ok(is_congruent(rat(83),     -2, 5));
ok(is_congruent(float(83),   -2, 5));

ok(is_congruent(int(83),     3,       rat(5)));
ok(is_congruent(rat(83),     3,       5));
ok(is_congruent(int(83),     int(3),  5));
ok(is_congruent(int(83),     3,       int(5)));
ok(is_congruent(int(83),     int(3),  int(5)));
ok(is_congruent(complex(83), 3,       float(5)));
ok(is_congruent(int(83),     -2,      int(5)));
ok(is_congruent(int(83),     int(-2), 5));
ok(is_congruent(complex(83), -2,      5));
ok(is_congruent(rat(83),     -2,      5));
ok(is_congruent(float(83),   -2,      5));

ok(!is_congruent(int(83),     1,  5));
ok(!is_congruent(rat(83),     1,  5));
ok(!is_congruent(complex(83), 1,  5));
ok(!is_congruent(int(83),     -1, 5));
ok(!is_congruent(complex(83), -1, 5));
ok(!is_congruent(rat(83),     -1, 5));
ok(!is_congruent(float(83),   -1, 5));

ok(is_rat(rat('1/2')));
ok(!is_rat(complex('3+4i')));
ok(is_rat('1234'));
ok(!is_rat('3+4i'));

ok(is_real(complex('4')));           # true
ok(not is_real(complex('4i')));      # false (is imaginary)
ok(not is_real(complex('3+4i')));    # false (is complex)

ok(not is_imag(complex('4')));       # false (is real)
ok(is_imag(complex('4i')));          # true
ok(not is_imag(complex('3+4i')));    # false (is complex)

ok(not is_complex(complex('4')));    # false (is real)
ok(not is_complex(complex('4i')));   # false (is imaginary)
ok(is_complex(complex('3+4i')));     # true

is(round('1234.567'), '1235');
is(round('1234.567',     2),  '1200');
is(round('3.123+4.567i', -2), '3.12+4.57i');

is(rat_approx('-0.6180339887'),    '-260497/421493');
is(rat_approx('1.008155930329'),   '7293/7234');
is(rat_approx('1.0019891835756'),  '524875/523833');
is(rat_approx('-529.12424242424'), '-174611/330');

is(rat_approx($o->new_q(1,  6)->as_dec),  '1/6');
is(rat_approx($o->new_q(13, 6)->as_dec),  '13/6');
is(rat_approx($o->new_q(6,  13)->as_dec), '6/13');

is(rat_approx($o->new_f('-5.0108932461873638344226579520697167755991285403')), '-2300/459');
is(rat_approx($o->new_f('-5.0544662309368191721132897603485838779956427015')), '-2320/459');

is(acmp(-3,              3),            0);
is(acmp(-4,              3),            1);
is(acmp(4,               -5),           -1);
is(acmp(-9,              -5),           1);
is(acmp('3+4i',          float(5)),     0);
is(acmp(complex('3+4i'), 5),            0);
is(acmp(complex('3+4i'), rat(5)),       0);
is(acmp(complex(42),     complex(-42)), 0);
is(acmp(rat(42),         complex(-42)), 0);
is(acmp(42,              complex(-43)), -1);

is(approx_cmp(Math::AnyNum::e()**(Math::AnyNum::pi() * Math::AnyNum::i()),     -1), 0);
is(approx_cmp(Math::AnyNum::e()**(Math::AnyNum::pi() * Math::AnyNum::i()) + 1, 0),  0);

is(approx_cmp(exp(Math::AnyNum::pi() * Math::AnyNum::i()),     -1), 0);
is(approx_cmp(exp(Math::AnyNum::pi() * Math::AnyNum::i()) + 1, 0),  0);

is(approx_cmp('3.14159265358979323846264338327950288419716939938', Math::AnyNum::pi), 0);
is(approx_cmp('3.1415926535897932384626433832795028841971693993',  Math::AnyNum::pi), -1);
is(approx_cmp('3.14159265358979323846264338327950288419716939939', Math::AnyNum::pi), 1);

is(approx_cmp('199573010111413366978755/63526062133920493691074', '237108599624676709032116/75474011359728834791267', -40), 0);
is(approx_cmp('199573010111413366978755/63526062133920493691074', '237108599624676709032116/75474011359728834791267', -50), 1);
