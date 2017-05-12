#!/usr/bin/perl -w

use strict;
use Test;

BEGIN
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 117;
  }

# testing of Math::BigInt::Pari, primarily for interface/api and not for the
# math functionality

use Math::BigInt::Pari;

my $C = 'Math::BigInt::Pari';	# pass classname to sub's

# _new and _str
my $x = $C->_new("123"); my $y = $C->_new("321");
ok (ref($x),'Math::Pari'); ok ($C->_str($x),123); ok ($C->_str($y),321);

# _add, _sub, _mul, _div

ok ($C->_str($C->_add($x,$y)),444);
ok ($C->_str($C->_sub($x,$y)),123);
ok ($C->_str($C->_mul($x,$y)),39483);
ok ($C->_str($C->_div($x,$y)),123);

ok ($C->_str($C->_mul($x,$y)),39483);
ok ($C->_str($x),39483);
ok ($C->_str($y),321);
my $z = $C->_new("2");
ok ($C->_str($C->_add($x,$z)),39485);
my ($re,$rr) = $C->_div($x,$y);

ok ($C->_str($re),123); ok ($C->_str($rr),2);

# _mod
$x = $C->_new("123"); $y = $C->_new("2");
ok ($C->_str($C->_mod($x,$y)),1);
$x = $C->_new("123"); $y = $C->_new("5");
ok ($C->_str($C->_mod($x,$y)),3);

# is_zero, _is_one, _one, _zero
ok ($C->_is_zero($x),0);
ok ($C->_is_one($x),0);

ok ($C->_is_one($C->_one()),1); ok ($C->_is_one($C->_zero()),0);
ok ($C->_is_zero($C->_zero()),1); ok ($C->_is_zero($C->_one()),0);

# _two, _ten, _is_two, is_ten
ok ($C->_is_ten($C->_ten()),1); ok ($C->_is_ten($C->_two()),0);
ok ($C->_is_two($C->_two()),1); ok ($C->_is_two($C->_ten()),0);

# is_odd, is_even
ok ($C->_is_odd($C->_one()),1); ok ($C->_is_odd($C->_zero()),0);
ok ($C->_is_even($C->_one()),0); ok ($C->_is_even($C->_zero()),1);

# _digit
$x = $C->_new("123456789");
ok ($C->_digit($x,0),9);
ok ($C->_digit($x,1),8);
ok ($C->_digit($x,2),7);
ok ($C->_digit($x,-1),1);
ok ($C->_digit($x,-2),2);
ok ($C->_digit($x,-3),3);

# _acmp
$x = $C->_new("123456789");
$y = $C->_new("987654321");
ok ($C->_acmp($x,$y),-1);
ok ($C->_acmp($y,$x),1);
ok ($C->_acmp($x,$x),0);
ok ($C->_acmp($y,$y),0);

# _div
$x = $C->_new("3333"); $y = $C->_new("1111");
ok ($C->_str( scalar $C->_div($x,$y)),3);
$x = $C->_new("33333"); $y = $C->_new("1111"); ($x,$y) = $C->_div($x,$y);
ok ($C->_str($x),30); ok ($C->_str($y),3);
$x = $C->_new("123"); $y = $C->_new("1111");
($x,$y) = $C->_div($x,$y); ok ($C->_str($x),0); ok ($C->_str($y),123);

# _and, _xor, _or
$x = $C->_new("7"); $y = $C->_new("5"); ok ($C->_str($C->_and($x,$y)),5);
$x = $C->_new("6"); $y = $C->_new("1"); ok ($C->_str($C->_or($x,$y)),7);
$x = $C->_new("9"); $y = $C->_new("6"); ok ($C->_str($C->_xor($x,$y)),15);

# _inc, _dec
$x = $C->_new("7"); ok ($C->_str($C->_inc($x)),8);
ok ($C->_str($C->_dec($x)),7);

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
  my ($x,$y,$r) = split /:/;
  $x = $C->_new($x); $y = $C->_new($y);
  ok ($C->_str($C->_pow($x,$y)),$r);
  }

# _num
$x = $C->_new("12345"); $x = $C->_num($x); ok (ref($x)||'',''); ok ($x,12345);

# _copy
$x = $C->_new("123"); $y = $C->_copy($x); $z = $C->_new("321");
$C->_add($x,$z);
ok ($C->_str($x),'444');
ok ($C->_str($y),'123');

# _gcd
$x = $C->_new("128"); $y = $C->_new('96'); $x = $C->_gcd($x,$y);
ok ($C->_str($x),'32');

# should not happen:
# $x = $C->_new("-2"); $y = $C->_new("4"); ok ($C->_acmp($x,$y),-1);

# _check
$x = $C->_new("123456789");
ok ($C->_check($x),0);
ok ($C->_check(123),'123 is not a reference to Math::Pari');

# _lsft, _rsft
$x = $C->_new("64"); $y = $C->_new("2");
$z = $C->_lsft($x,$y,2);
ok ($C->_str($z),'256');
$z = $C->_rsft($x,$y,2);
ok ($C->_str($z),'64');

$x = $C->_new("64"); $y = $C->_new("2");
$z = $C->_lsft($x,$y,10);
ok ($C->_str($z),'6400');

$z = $C->_rsft($z,$y,10);
ok ($C->_str($z),'64');

# _sqrt
$x = $C->_new("144"); ok ($C->_str($C->_sqrt($x)),12);
$x = $C->_new("145"); ok ($C->_str($C->_sqrt($x)),12);
$x = $C->_new("143"); ok ($C->_str($C->_sqrt($x)),11);

# _root
$y = $C->_new("2");
$x = $C->_new("144"); ok ($C->_str($C->_root($x,$y)),12);
$x = $C->_new("145"); ok ($C->_str($C->_root($x,$y)),12);
$x = $C->_new("143"); ok ($C->_str($C->_root($x,$y)),11);

$y = $C->_new("3");
$x = $C->_new("81"); ok ($C->_str($C->_root($x,$y)),4);
$x = $C->_new("82"); ok ($C->_str($C->_root($x,$y)),4);
$x = $C->_new("80"); ok ($C->_str($C->_root($x,$y)),4);

$y = $C->_new("4");
$x = $C->_new("81"); ok ($C->_str($C->_root($x,$y)),3);
$x = $C->_new("82"); ok ($C->_str($C->_root($x,$y)),3);
$x = $C->_new("80"); ok ($C->_str($C->_root($x,$y)),2);

# _fac
$x = $C->_new("0"); ok ($C->_str($C->_fac($x)),1);
$x = $C->_new("1"); ok ($C->_str($C->_fac($x)),1);
$x = $C->_new("2"); ok ($C->_str($C->_fac($x)),2);
$x = $C->_new("3"); ok ($C->_str($C->_fac($x)),6);
$x = $C->_new("4"); ok ($C->_str($C->_fac($x)),24);
$x = $C->_new("5"); ok ($C->_str($C->_fac($x)),120);
$x = $C->_new("6"); ok ($C->_str($C->_fac($x)),720);
$x = $C->_new("7"); ok ($C->_str($C->_fac($x)),5040);

# _as_hex
$x = $C->_new("0"); ok ($C->_as_hex($x),'0x0');
$x = $C->_new("1"); ok ($C->_as_hex($x),'0x1');
$x = $C->_new("16"); ok ($C->_as_hex($x),'0x10');
# _from_hex
$x = $C->_from_hex("0x0"); ok ($C->_as_hex($x),'0x0');
$x = $C->_from_hex("0x10"); ok ($C->_as_hex($x),'0x10');

# _as_bin
$x = $C->_new("0"); ok ($C->_as_bin($x),'0b0');
$x = $C->_new("1"); ok ($C->_as_bin($x),'0b1');
$x = $C->_new("16"); ok ($C->_as_bin($x),'0b10000');
# _from_bin
$x = $C->_from_bin("0b001"); ok ($C->_as_bin($x),'0b1');
$x = $C->_from_bin("0b101"); ok ($C->_as_bin($x),'0b101');

# _from_oct
$x = $C->_from_oct("001"); ok ($C->_str($x),'1');
$x = $C->_from_oct("07"); ok ($C->_str($x),'7');
$x = $C->_from_oct("077"); ok ($C->_str($x),'63');
$x = $C->_from_oct("07654321"); ok ($C->_str($x),'2054353');
# _as_oct
$x = $C->_new("2054353"); ok ($C->_as_oct($x),'07654321');
$x = $C->_new("63"); ok ($C->_as_oct($x),'077');
$x = $C->_new("0"); ok ($C->_as_oct($x),'00');

# _modinv
$x = $C->_new("8"); $y = $C->_new("5033");
my ($res,$sign) = $C->_modinv($x,$y);
ok ( join(":", $C->_str($res), $sign), "629:-");

# _zeros
ok ($C->_zeros($C->_new("0")), 0);
ok ($C->_zeros($C->_new("12")), 0);
ok ($C->_zeros($C->_new("10")), 1);
ok ($C->_zeros($C->_new("109")), 0);
ok ($C->_zeros($C->_new("108")), 0);
ok ($C->_zeros($C->_new("100")), 2);

# _1ex
ok ($C->_str($C->_1ex(0)), $C->_new("1"));
ok ($C->_str($C->_1ex(1)), $C->_new("10"));
ok ($C->_str($C->_1ex(2)), $C->_new("100"));
ok ($C->_str($C->_1ex(12)), $C->_new("1000000000000"));
ok ($C->_str($C->_1ex(16)), $C->_new("10000000000000000"));

# done

1;
