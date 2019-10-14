#!perl

use strict;
use warnings;

use Test::More tests => 68;

# testing of Math::BigInt::BitVect

use Math::BigInt::BitVect;

my $LIB = 'Math::BigInt::BitVect'; # pass classname to sub's

# _new and _str
my $x = $LIB->_new("123");
my $y = $LIB->_new("321");
is(ref($x), 'Bit::Vector', 'ref($x)');
is($LIB->_str($x), 123, '$x is 123');
is($LIB->_str($y), 321, '$y is 321');

# _add, _sub, _mul, _div

is($LIB->_str($LIB->_add($x, $y)), 444);
is($LIB->_str($LIB->_sub($x, $y)), 123);
is($LIB->_str($LIB->_mul($x, $y)), 39483);
is($LIB->_str($LIB->_div($x, $y)), 123);

is($LIB->_str($LIB->_mul($x, $y)), 39483);
is($LIB->_str($x), 39483);
is($LIB->_str($y), 321);
my $z = $LIB->_new("2");
is($LIB->_str($LIB->_add($x, $z)), 39485);
my ($re, $rr) = $LIB->_div($x, $y);

is($LIB->_str($re), 123);
is($LIB->_str($rr), 2);

# is_zero, _is_one, _one, _zero
is($LIB->_is_zero($x), 0);
is($LIB->_is_one($x), 0);

is($LIB->_is_one($LIB->_one()), 1);
is($LIB->_is_one($LIB->_zero()), 0);

is($LIB->_is_zero($LIB->_zero()), 1);
is($LIB->_is_zero($LIB->_one()), 0);

# is_odd, is_even
is($LIB->_is_odd($LIB->_one()), 1);
is($LIB->_is_odd($LIB->_zero()), 0);

is($LIB->_is_even($LIB->_one()), 0);
is($LIB->_is_even($LIB->_zero()), 1);

# _digit
$x = $LIB->_new("123456789");
is($LIB->_digit($x, 0), 9);
is($LIB->_digit($x, 1), 8);
is($LIB->_digit($x, 2), 7);
is($LIB->_digit($x, -1), 1);
is($LIB->_digit($x, -2), 2);
is($LIB->_digit($x, -3), 3);

# _acmp
$x = $LIB->_new("123456789");
$y = $LIB->_new("987654321");
is($LIB->_acmp($x, $y), -1);
is($LIB->_acmp($y, $x), 1);
is($LIB->_acmp($x, $x), 0);
is($LIB->_acmp($y, $y), 0);

# _div
$x = $LIB->_new("3333");
$y = $LIB->_new("1111");
is($LIB->_str( scalar $LIB->_div($x, $y)), 3);

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

# _and, _xor, _or

$x = $LIB->_new("7");
$y = $LIB->_new("5");
is($LIB->_str($LIB->_and($x, $y)), 5);

$x = $LIB->_new("6");
$y = $LIB->_new("1");
is($LIB->_str($LIB->_or($x, $y)), 7);

$x = $LIB->_new("9");
$y = $LIB->_new("6");
is($LIB->_str($LIB->_xor($x, $y)), 15);

# _inc, _dec

$x = $LIB->_new("7");
is($LIB->_str($LIB->_inc($x)), 8);

$x = $LIB->_new("7");
is($LIB->_str($LIB->_dec($x)), 6);

# _lsft, _rsft
$x = $LIB->_new("7");
$y = $LIB->_new("1");
is($LIB->_str($LIB->_lsft($x, $y, 2)), 14);

$x = $LIB->_new("15");
$y = $LIB->_new("1");
is($LIB->_str($LIB->_rsft($x, $y, 2)), 7);

$x = $LIB->_new("7");
$y = $LIB->_new("1");
is($LIB->_str($LIB->_lsft($x, $y, 10)), 70);

$x = $LIB->_new("723");
$y = $LIB->_new("2");
is($LIB->_str($LIB->_rsft($x, $y, 10)), 7);

# check that __reduce really works
my $v = '1' . '0' x 1000;
$x = $LIB->_new($v);
$v = '1' . '0' x 999;
$y = $LIB->_new($v);
is($LIB->_str($LIB->_div($x, $y)), 10);
is($x->Size(), 32);             # min chunk size => 32 bit

my $r;
# to check bit-counts
foreach (qw/
               7:7:823543
               31:7:27512614111
               2:10:1024
               32:4:1048576
               64:8:281474976710656
               128:16:5192296858534827628530496329220096
               255:32:102161150204658159326162171757797299165741800222807601117528975009918212890625
               1024:64:4562440617622195218641171605700291324893228507248559930579192517899275167208677386505912811317371399778642309573594407310688704721375437998252661319722214188251994674360264950082874192246603776 /)
{
    my ($x, $y, $r) = split /:/;
    $x = $LIB->_new($x);
    $y = $LIB->_new($y);
    is($LIB->_str($LIB->_pow($x, $y)), $r);
}

# _num
$x = $LIB->_new("12345");
$x = $LIB->_num($x);
is(ref($x)||'', '');
is($x, 12345);

# _fac
$x = $LIB->_new("1");
$x = $LIB->_fac($x);
is($LIB->_str($x), '1');

$x = $LIB->_new("2");
$x = $LIB->_fac($x);
is($LIB->_str($x), '2');

$x = $LIB->_new("3");
$x = $LIB->_fac($x);
is($LIB->_str($x), '6');

$x = $LIB->_new("4");
$x = $LIB->_fac($x);
is($LIB->_str($x), '24');

# _copy
$x = $LIB->_new("123");
$y = $LIB->_copy($x);
$z = $LIB->_new("321");
$LIB->_add($x, $z);
is($LIB->_str($x), '444');
is($LIB->_str($y), '123');

# _gcd
$x = $LIB->_new("128");
$y = $LIB->_new('96');
$x = $LIB->_gcd($x, $y);
is($LIB->_str($x), '32');

# should not happen:
# $x = $LIB->_new("-2");
# $y = $LIB->_new("4");
# is($LIB->_acmp($x, $y), -1);

# _check
$x = $LIB->_new("123456789");
is($LIB->_check($x), 0);
is($LIB->_check(123), '123 is not a reference to Bit::Vector');

# done

1;
