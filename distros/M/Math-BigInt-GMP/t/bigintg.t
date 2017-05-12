#!perl

use strict;
use warnings;

use Test::More tests => 356;;

use Math::BigInt::GMP;

# testing of Math::BigInt::GMP

my $LIB = 'Math::BigInt::GMP';            # pass classname to sub's

# _new and _str
my $x = $LIB->_new("123");
my $y = $LIB->_new("321");
is(ref($x), 'Math::BigInt::GMP');
is($LIB->_str($x), 123);
is($LIB->_str($y), 321);

###############################################################################

note "_set()";

my $b = $LIB->_new("123");
$LIB->_set($b, 12);
is($LIB->_str($b), 12);

###############################################################################

note "_add(), _sub(), _mul(), _div()";

is($LIB->_str($LIB->_add($x, $y)), 444);
is($LIB->_str($LIB->_sub($x, $y)), 123);
is($LIB->_str($x), 123);
is($LIB->_str($y), 321);
is($LIB->_str($LIB->_mul($x, $y)), 39483);
is($LIB->_str(scalar $LIB->_div($x, $y)), 123);

# check that mul/div doesn't change $y
# and returns the same reference, not something new

is($LIB->_str($LIB->_mul($x, $y)), 39483);
is($LIB->_str($x), 39483);
is($LIB->_str($y), 321);

is($LIB->_str(scalar $LIB->_div($x, $y)), 123);
is($LIB->_str($x), 123);
is($LIB->_str($y), 321);

$x = $LIB->_new("39483");
my ($x1, $r1) = $LIB->_div($x, $y);
is("$x1", "$x");
$LIB->_inc($x1);
is("$x1", "$x");
is($LIB->_str($r1), '0');

# check that sub modifies the right argument:

$x = $LIB->_new("221");
$y = $LIB->_new("444");

$x = $LIB->_sub($y, $x, 1);                       # 444 - 221 => 223

is($LIB->_str($x), 223);
is($LIB->_str($y), 444);

$x = $LIB->_new("444");
$y = $LIB->_new("221");

is($LIB->_str($LIB->_sub($x, $y)), 223);    # 444 - 221 => 223

is($LIB->_str($x), 223);
is($LIB->_str($y), 221);

###############################################################################

$x = $LIB->_new("39483"); # reset
$y = $LIB->_new("321");   # reset

my $z = $LIB->_new("2");
is($LIB->_str($LIB->_add($x, $z)), 39485);
my ($re, $rr) = $LIB->_div($x, $y);

is($LIB->_str($re), 123);
is($LIB->_str($rr), 2);

##############################################################################

note "is_zero()";

is($LIB->_is_zero($x) || 0, 0);

note "_is_one()";

is($LIB->_is_one($x)  || 0, 0);

note "_one()";

is($LIB->_str($LIB->_zero()), "0");

note "_zero()";

is($LIB->_str($LIB->_one()),  "1");

##############################################################################

note "_two()";

is($LIB->_str($LIB->_two()), "2");
is($LIB->_is_ten($LIB->_two()), 0);
is($LIB->_is_two($LIB->_two()), 1);

note "_ten()";

is($LIB->_str($LIB->_ten()), "10");
is($LIB->_is_ten($LIB->_ten()), 1);
is($LIB->_is_two($LIB->_ten()), 0);

is($LIB->_is_one($LIB->_one()), 1);
is($LIB->_is_one($LIB->_two()), 0);
is($LIB->_is_one($LIB->_ten()), 0);

is($LIB->_is_one($LIB->_zero()) || 0, 0);

is($LIB->_is_zero($LIB->_zero()), 1);

is($LIB->_is_zero($LIB->_one()) || 0, 0);

###############################################################################

note "is_odd()";

is($LIB->_is_odd($LIB->_one()), 1);
is($LIB->_is_odd($LIB->_zero()) || 0, 0);

note "is_even()";

is($LIB->_is_even($LIB->_one()) || 0, 0);
is($LIB->_is_even($LIB->_zero()), 1);

###############################################################################

note "_len() and _alen()";

sub _check_len {
    my ($str, $method) = @_;

    my $n  = length($str);
    my $x = $LIB->_new($str);

    # _len() is exact
    is($LIB->_len($x), $n);

    # _alen() is equal or at most one bigger
    my $alen = $LIB->_alen($x);
    ok($n -1 <= $alen && $alen <= $n + 1,
       qq|\$x = $LIB->_new("$str"); $LIB->_alen(\$x)|)
      or diag sprintf <<"EOF", $alen, $n - 1, $n, $n + 1;
         got: '%d'
    expected: '%d', '%d' or '%d'
EOF
}

_check_len("1");
_check_len("12");
_check_len("123");
_check_len("1234");
_check_len("12345");
_check_len("123456");
_check_len("1234567");
_check_len("12345678");
_check_len("123456789");
_check_len("1234567890");
_check_len("7");
_check_len("8");
_check_len("9");
_check_len("10");
_check_len("11");
_check_len("21");
_check_len("321");
_check_len("320");
_check_len("4321");
_check_len("54321");
_check_len("654321");
_check_len("7654321");
_check_len("7654321");
_check_len("87654321");
_check_len("987654321");
_check_len("9876543219876543210");
_check_len("1234567890" x 10);
_check_len("1234567890" x 100);

for (my $i = 1; $i < 9; $i++) {
    my $a = "$i" . '0' x ($i-1);
    _check_len($a);
}

###############################################################################

note "_digit()";

$x = $LIB->_new("123456789");
is($LIB->_digit($x, 0), 9);
is($LIB->_digit($x, 1), 8);
is($LIB->_digit($x, 2), 7);
is($LIB->_digit($x, -1), 1);
is($LIB->_digit($x, -2), 2);
is($LIB->_digit($x, -3), 3);

###############################################################################

note "_copy()";

foreach (qw/ 1 12 123 1234 12345 123456 1234567 12345678 123456789/) {
    $x = $LIB->_new("$_");
    is($LIB->_str($LIB->_copy($x)), "$_");
    is($LIB->_str($x), "$_");     # did _copy destroy original x?
}

###############################################################################

note "_zeros()";

$x = $LIB->_new("1256000000");
is($LIB->_zeros($x), 6);

$x = $LIB->_new("152");
is($LIB->_zeros($x), 0);

$x = $LIB->_new("123000");
is($LIB->_zeros($x), 3);

$x = $LIB->_new("123001");
is($LIB->_zeros($x), 0);

$x = $LIB->_new("1");
is($LIB->_zeros($x), 0);

$x = $LIB->_new("8");
is($LIB->_zeros($x), 0);

$x = $LIB->_new("10");
is($LIB->_zeros($x), 1);

$x = $LIB->_new("11");
is($LIB->_zeros($x), 0);

$x = $LIB->_new("0");
is($LIB->_zeros($x), 0);

###############################################################################

note "_lsft()";

$x = $LIB->_new("10");
$y = $LIB->_new("3");
is($LIB->_str($LIB->_lsft($x, $y, 10)), 10000);

$x = $LIB->_new("20");
$y = $LIB->_new("3");
is($LIB->_str($LIB->_lsft($x, $y, 10)), 20000);

$x = $LIB->_new("128");
$y = $LIB->_new("4");
is($LIB->_str($LIB->_lsft($x, $y, 2)), 128 << 4);

note "_rsft()";

$x = $LIB->_new("1000");
$y = $LIB->_new("3");
is($LIB->_str($LIB->_rsft($x, $y, 10)), 1);

$x = $LIB->_new("20000");
$y = $LIB->_new("3");
is($LIB->_str($LIB->_rsft($x, $y, 10)), 20);

$x = $LIB->_new("256");
$y = $LIB->_new("4");
is($LIB->_str($LIB->_rsft($x, $y, 2)), 256 >> 4);

$x = $LIB->_new("6411906467305339182857313397200584952398");
$y = $LIB->_new("45");
is($LIB->_str($LIB->_rsft($x, $y, 10)), 0);

###############################################################################

note "_acmp()";

$x = $LIB->_new("123456789");
$y = $LIB->_new("987654321");
is($LIB->_acmp($x, $y), -1);
is($LIB->_acmp($y, $x), 1);
is($LIB->_acmp($x, $x), 0);
is($LIB->_acmp($y, $y), 0);
$x = $LIB->_new("12");
$y = $LIB->_new("12");
is($LIB->_acmp($x, $y), 0);
$x = $LIB->_new("21");
is($LIB->_acmp($x, $y), 1);
is($LIB->_acmp($y, $x), -1);
$x = $LIB->_new("123456789");
$y = $LIB->_new("1987654321");
is($LIB->_acmp($x, $y), -1);
is($LIB->_acmp($y, $x), +1);

$x = $LIB->_new("1234567890123456789");
$y = $LIB->_new("987654321012345678");
is($LIB->_acmp($x, $y), 1);
is($LIB->_acmp($y, $x), -1);
is($LIB->_acmp($x, $x), 0);
is($LIB->_acmp($y, $y), 0);

$x = $LIB->_new("1234");
$y = $LIB->_new("987654321012345678");
is($LIB->_acmp($x, $y), -1);
is($LIB->_acmp($y, $x), 1);
is($LIB->_acmp($x, $x), 0);
is($LIB->_acmp($y, $y), 0);

###############################################################################

note "_modinv()";

$x = $LIB->_new("8");
$y = $LIB->_new("5033");
my ($xmod, $sign) = $LIB->_modinv($x, $y);
is($LIB->_str($xmod), '4404');
           # (4404 * 8) % 5033 = 1
is($sign, '+');

###############################################################################

note "_div()";

$x = $LIB->_new("3333");
$y = $LIB->_new("1111");
is($LIB->_str(scalar $LIB->_div($x, $y)), 3);
$x = $LIB->_new("33333");
$y = $LIB->_new("1111");
($x, $y) = $LIB->_div($x, $y);
is($LIB->_str($x), 30);
is($LIB->_str($y), 3);
$x = $LIB->_new("123");
$y = $LIB->_new("1111");
($x, $y) = $LIB->_div($x, $y);
is($LIB->_str($x), 0);
is($LIB->_str($y), 123);

###############################################################################

note "_num()";

foreach (qw/1 12 123 1234 12345 1234567 12345678 123456789 1234567890/) {
    $x = $LIB->_new("$_");
    is(ref($x) || '', 'Math::BigInt::GMP');
    is($LIB->_str($x), "$_");
    $x = $LIB->_num($x);
    is(ref($x) || '', '');
    is($x, $_);
}

###############################################################################

note "_sqrt()";

$x = $LIB->_new("144");
is($LIB->_str($LIB->_sqrt($x)), '12');
$x = $LIB->_new("144000000000000");
is($LIB->_str($LIB->_sqrt($x)), '12000000');

###############################################################################

note "_root()";

$x = $LIB->_new("81");
my $n = $LIB->_new("3");
is($LIB->_str($LIB->_root($x, $n)), '4');   # 4*4*4 = 64, 5*5*5 = 125

$x = $LIB->_new("81");
$n = $LIB->_new("4");
is($LIB->_str($LIB->_root($x, $n)), '3');   # 3*3*3*3 == 81

###############################################################################

note "_pow() (and _root())";

$x = $LIB->_new("0");
$n = $LIB->_new("3");
is($LIB->_str($LIB->_pow($x, $n)), 0);      # 0 ** y => 0

$x = $LIB->_new("3");
$n = $LIB->_new("0");
is($LIB->_str($LIB->_pow($x, $n)), 1);      # x ** 0 => 1

$x = $LIB->_new("1");
$n = $LIB->_new("3");
is($LIB->_str($LIB->_pow($x, $n)), 1);      # 1 ** y => 1

$x = $LIB->_new("5");
$n = $LIB->_new("1");
is($LIB->_str($LIB->_pow($x, $n)), 5);      # x ** 1 => x

$x = $LIB->_new("81");
$n = $LIB->_new("3");

is($LIB->_str($LIB->_pow($x, $n)), 81 ** 3);    # 81 ** 3 == 531441

is($LIB->_str($LIB->_root($x, $n)), 81);

$x = $LIB->_new("81");
is($LIB->_str($LIB->_pow($x, $n)), 81 ** 3);
is($LIB->_str($LIB->_pow($x, $n)), '150094635296999121');   # 531441 ** 3 ==

is($LIB->_str($LIB->_root($x, $n)), '531441');
is($LIB->_str($LIB->_root($x, $n)), '81');

$x = $LIB->_new("81");
$n = $LIB->_new("14");
is($LIB->_str($LIB->_pow($x, $n)), '523347633027360537213511521');
is($LIB->_str($LIB->_root($x, $n)), '81');

$x = $LIB->_new("523347633027360537213511520");
is($LIB->_str($LIB->_root($x, $n)), '80');

$x = $LIB->_new("523347633027360537213511522");
is($LIB->_str($LIB->_root($x, $n)), '81');

my $res = [ qw/ 9 31 99 316 999 3162 9999/ ];

# 99 ** 2 = 9801, 999 ** 2 = 998001 etc
for my $i (2 .. 9) {
    $x = '9' x $i;
    $x = $LIB->_new($x);
    $n = $LIB->_new("2");
    my $rc = '9' x ($i-1). '8' . '0' x ($i-1) . '1';
    is($LIB->_str($LIB->_pow($x, $n)), $rc,
       "_pow(" . ('9' x $i) . ", 2)");

    if ($i <= 7) {
        $x = '9' x $i;
        $x = $LIB->_new($x);
        $n = '9' x $i;
        $n = $LIB->_new($n);
        is($LIB->_str($LIB->_root($x, $n)), '1',
           "_root(" . ('9' x $i) . ", " . (9 x $i) . ")");


        $x = '9' x $i;
        $x = $LIB->_new($x);
        $n = $LIB->_new("2");
        is($LIB->_str($LIB->_root($x, $n)), $res->[$i-2],
           "_root(" . ('9' x $i) . ", " . (9 x $i) . ")");
    }
}

##############################################################################
# _fac

$x = $LIB->_new("0");
is($LIB->_str($LIB->_fac($x)), '1');

$x = $LIB->_new("1");
is($LIB->_str($LIB->_fac($x)), '1');

$x = $LIB->_new("2");
is($LIB->_str($LIB->_fac($x)), '2');

$x = $LIB->_new("3");
is($LIB->_str($LIB->_fac($x)), '6');

$x = $LIB->_new("4");
is($LIB->_str($LIB->_fac($x)), '24');

$x = $LIB->_new("5");
is($LIB->_str($LIB->_fac($x)), '120');

$x = $LIB->_new("10");
is($LIB->_str($LIB->_fac($x)), '3628800');

$x = $LIB->_new("11");
is($LIB->_str($LIB->_fac($x)), '39916800');

$x = $LIB->_new("12");
is($LIB->_str($LIB->_fac($x)), '479001600');

$x = $LIB->_new("13");
is($LIB->_str($LIB->_fac($x)), '6227020800');

# test that _fac modifes $x in place for small arguments

$x = $LIB->_new("3");  $LIB->_fac($x); is($LIB->_str($x), '6');
$x = $LIB->_new("13"); $LIB->_fac($x); is($LIB->_str($x), '6227020800');

##############################################################################

note "_inc() and _dec()";

foreach (qw/1 11 121 1231 12341 1234561 12345671 123456781 1234567891/) {
    $x = $LIB->_new("$_");
    $LIB->_inc($x);
    print "# \$x = ", $LIB->_str($x), "\n"
      unless is($LIB->_str($x), substr($_, 0, length($_)-1) . '2');
    $LIB->_dec($x);
    is($LIB->_str($x), $_);
}

foreach (qw/19 119 1219 12319 1234519 12345619 123456719 1234567819/) {
    $x = $LIB->_new("$_");
    $LIB->_inc($x);
    print "# \$x = ", $LIB->_str($x), "\n"
      unless is($LIB->_str($x), substr($_, 0, length($_)-2) . '20');
    $LIB->_dec($x);
    is($LIB->_str($x), $_);
}

foreach (qw/999 9999 99999 9999999 99999999 999999999 9999999999 99999999999/) {
    $x = $LIB->_new("$_");
    $LIB->_inc($x);
    print "# \$x = ", $LIB->_str($x), "\n"
      unless is($LIB->_str($x), '1' . '0' x (length($_)));
    $LIB->_dec($x);
    is($LIB->_str($x), $_);
}

$x = $LIB->_new("1000");
$LIB->_inc($x);
is($LIB->_str($x), '1001');
$LIB->_dec($x);
is($LIB->_str($x), '1000');

###############################################################################

note "_log_int()";

# test handling of plain scalar as base, bug up to v1.17)

$x = $LIB->_new("81");

my ($r, $exact) = $LIB->_log_int($x, $LIB->_new("3"));
is($LIB->_str($r), '4');
ok($LIB->_str($x) eq '81' || $LIB->_str($x) eq '4');
is($exact, 1);

$x = $LIB->_new("81");

($r, $exact) = $LIB->_log_int($x, 3);
is($LIB->_str($r), '4');
ok($LIB->_str($x) eq '81' || $LIB->_str($x) eq '4');
is($exact, 1);

###############################################################################

note "_mod()";

$x = $LIB->_new("1000");
$y = $LIB->_new("3");
is($LIB->_str(scalar $LIB->_mod($x, $y)), 1);
$x = $LIB->_new("1000");
$y = $LIB->_new("2");
is($LIB->_str(scalar $LIB->_mod($x, $y)), 0);

###############################################################################

note "_and(), _or(), _xor()";

$x = $LIB->_new("5");
$y = $LIB->_new("2");
is($LIB->_str(scalar $LIB->_xor($x, $y)), 7);
$x = $LIB->_new("5");
$y = $LIB->_new("2");
is($LIB->_str(scalar $LIB->_or($x, $y)), 7);
$x = $LIB->_new("5");
$y = $LIB->_new("3");
is($LIB->_str(scalar $LIB->_and($x, $y)), 1);

###############################################################################

note "_from_hex() and _from_bin()";

is($LIB->_str($LIB->_from_hex("0xFf")), 255);
is($LIB->_str($LIB->_from_bin("0b10101011")), 160+11);

###############################################################################

note "_as_hex() and _as_bin()";

is($LIB->_str($LIB->_from_hex($LIB->_as_hex($LIB->_new("128")))), 128);
is($LIB->_str($LIB->_from_bin($LIB->_as_bin($LIB->_new("128")))), 128);
is($LIB->_str($LIB->_from_hex($LIB->_as_hex($LIB->_new("0")))), 0);
is($LIB->_str($LIB->_from_bin($LIB->_as_bin($LIB->_new("0")))), 0);
is($LIB->_as_hex($LIB->_new("0")), '0x0');
is($LIB->_as_bin($LIB->_new("0")), '0b0');
is($LIB->_as_hex($LIB->_new("12")), '0xc');
is($LIB->_as_bin($LIB->_new("12")), '0b1100');

###############################################################################

note "_from_oct()";

$x = $LIB->_from_oct("001");      is($LIB->_str($x), '1');
$x = $LIB->_from_oct("07");       is($LIB->_str($x), '7');
$x = $LIB->_from_oct("077");      is($LIB->_str($x), '63');
$x = $LIB->_from_oct("07654321"); is($LIB->_str($x), '2054353');

###############################################################################

note "_as_oct()";

$x = $LIB->_new("2054353"); is($LIB->_as_oct($x), '07654321');
$x = $LIB->_new("63");      is($LIB->_as_oct($x), '077');
$x = $LIB->_new("0");       is($LIB->_as_oct($x), '00');

###############################################################################

note "_1ex()";

is($LIB->_str($LIB->_1ex(0)), "1");
is($LIB->_str($LIB->_1ex(1)), "10");
is($LIB->_str($LIB->_1ex(2)), "100");
is($LIB->_str($LIB->_1ex(12)), "1000000000000");
is($LIB->_str($LIB->_1ex(16)), "10000000000000000");

###############################################################################

note "_check()";

$x = $LIB->_new("123456789");
is($LIB->_check($x), 0);
is($LIB->_check(123), '123 is not a reference to Math::BigInt::GMP');

# done

1;
