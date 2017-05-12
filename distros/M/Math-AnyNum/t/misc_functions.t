#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 248;

use Math::AnyNum qw(:misc);

my $o = 'Math::AnyNum';

is(rand(0), 0);
ok(rand(1) < 1,     'rand(1) < 1');
ok(rand(0.2) < 0.2, 'rand(0.2) < 0.2');

ok(rand(0, 2) < 2,       'rand(2) < 2');
ok(rand(0, 1000) < 1000, 'rand(0, 1000) < 1000');

is(irand(0), 0);
ok(irand(1) <= 1, 'irand(1) <= 1');
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

is(numerator('3/4'),           '3');
is(numerator('123/567'),       '41');           # simplifies to '41/189'
is(numerator(int(42)),         '42');
is(numerator(rat('123/567')),  '41');           # simplifies to '41/189'
is(numerator(float('12')),     '12');
is(numerator(float('0.75')),   '3');            # '3/4'
is(numerator(complex('12')),   '12');
is(numerator(complex('0.75')), '3');            # '3/4'
is(numerator('0.75'),          '3');            # '3/4'
is(numerator(complex('3+4i')), 'NaN');
is(numerator("-42"),           "-42");

is(denominator('3/4'),           '4');
is(denominator('123/567'),       '189');        # simplifies to '41/189'
is(denominator(int(42)),         '1');
is(denominator(rat('123/567')),  '189');        # simplifies to '41/189'
is(denominator(float('12')),     '1');
is(denominator(float('0.75')),   '4');          # '3/4'
is(denominator(complex('12')),   '1');
is(denominator(complex('0.75')), '4');          # '3/4'
is(denominator('0.75'),          '4');          # '3/4'
is(denominator(complex('3+4i')), 'NaN');
is(denominator("-42"),           "1");

is(join(' ', digits('1234')),      '1 2 3 4');
is(join(' ', digits('1234.5678')), '1 2 3 4');    # only the integer part is considered
is(join(' ', digits('-1234')),     '1 2 3 4');
is(join(' ', digits('1234',           16)),          '4 d 2');
is(join(' ', digits($o->new('1234'),  16)),          '4 d 2');
is(join(' ', digits($o->new('1234'),  $o->new(16))), '4 d 2');
is(join(' ', digits('1234',           $o->new(16))), '4 d 2');
is(join(' ', digits($o->new('-1234'), 36)),          'y a');
is(join(' ', digits('-1234',          2)),           '1 0 0 1 1 0 1 0 0 1 0');

is(as_bin(42), '101010');
is(as_oct(42), '52');
is(as_hex(42), '2a');

is(as_bin(complex(42)), '101010');
is(as_oct(rat(42)),     '52');
is(as_hex(float(42)),   '2a');

is(as_int('255',          16), 'ff');
is(as_int(rat('255'),     16), 'ff');
is(as_int(float('255'),   16), 'ff');
is(as_int(complex('255'), 16), 'ff');

is(as_int('42.99',  10),        '42');
is(as_int('-42.99', "10.0001"), '-42');

is(as_int('12.5',  rat(16)),     'c');
is(as_int('-12.5', float(16)),   '-c');
is(as_int('-12.5', complex(16)), '-c');

is(as_frac('123/567'),       '41/189');
is(as_frac('42'),            '42/1');
is(as_frac(complex('0.75')), '3/4');
is(as_frac(float('0.75')),   '3/4');

is(as_frac('123/567',     16),          '29/bd');
is(as_frac(rat('43/255'), 16),          '2b/ff');
is(as_frac(rat('43/255'), complex(16)), '2b/ff');
is(as_frac(float('0.75'), rat(2)),      '11/100');

is(as_dec(sqrt(float(2)),   3), '1.41');
is(as_dec(sqrt(rat(2)),     4), '1.414');
is(as_dec(sqrt(complex(2)), 5), '1.4142');

is(as_dec('0.5'), '0.5');
is(as_dec('0.5',      10), '0.5');
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

ok(is_odd(int('43')));
ok(is_odd(rat('43')));
ok(is_odd(float('43')));
ok(is_odd(complex('43')));

ok(is_div('42',           '2'));
ok(is_div('4i',           '2'));
ok(is_div(complex('12i'), '3'));
ok(is_div('17',           '17/5'));
ok(is_div('17',           '3.4'));
ok(is_div('17',           complex('3.4')));
ok(is_div(float('17'),    complex('3.4')));
ok(is_div(rat('17'),      complex('3.4')));
ok(is_div(complex('17'),  complex('3.4')));

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
