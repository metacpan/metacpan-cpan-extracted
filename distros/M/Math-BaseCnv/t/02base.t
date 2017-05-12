#!/usr/bin/perl
# 37KK2jPD:02base.t created by PipStuart <Pip@CPAN.Org> to validate Math::BaseCnv functionality.
#   This script mimics Ken Williams' <Ken@Forums.Swathmore.Edu> test cases for his Math::BaseCalc module. I have included dig() function calls with most
#     tests out of respect for BaseCalc even though the only necessary calls are the ones that set the digits to something other than '0'..'9', 'A'..'Z'
#     since my Math::BaseCnv diginit() function initializes the digit list with good characters for any small common number bases. My benchmarks showed
#     BaseCnv to require about 3/4ths of the execution time needed by BaseCalc when including all the unnecessary dig() calls && about twice as fast when
#     dig() is only called when it must be. BaseCalc may not need all the $calc->digits() calls either though so that last one is probably an unfair
#     performance comparison. Besides speed, conversion functions make more sense to me than objects since I want to use them so frequently... even if
#     Perl's hex() built-in was the opposite behavior of mine (but now mine is called heX() to distinguish).
#   Before `make install' is performed this script should be run with `make test'. After `make install' it should work as `perl 02base.t`.
use strict;use warnings;use utf8;use Test;use Math::BaseCnv qw(:all);
my $calc;my $rslt;my $tnum=1;my $lded=1;my $tvrb=0;my $tsts=31;
END { print "not " unless($lded); print "ok $tsts\n"; }
plan('tests' => $tsts); &rprt(1);
sub rprt { # prints a rprt of test progress
  my $badd = !shift();
  print 'not ' if($badd);
  print "ok ", $tnum++, "\n";
  print @_ if(($ENV{'TEST_VERBOSE'} || $tvrb) && $badd);}
#$calc = new Math::BaseCalc(digits=>[0,1]);
dig( [ '0', '1' ] );
$calc = 2;
&rprt($calc);
#$rslt = $calc->from_base('01101');
$rslt = cnv('01101', 2, 10);
&rprt($rslt == 13, "$rslt\n");
#$calc->digits('bin');
#$rslt = $calc->from_base('1101');
dig('bin'); 
$rslt = cnv('1101', 2, 10);
&rprt($rslt == 13, "$rslt\n");
#$rslt = $calc->to_base(13);
$rslt = cnv(13, 2); # omitting last param assumes first is already 10 to ?
&rprt($rslt eq '1101', "$rslt\n");
#$calc->digits('hex');
#$rslt = $calc->to_base(46);
dig('heX'); 
$rslt = heX(46);
&rprt($rslt eq '2e', "$rslt\n");
#$calc->digits([qw(i  a m  v e r y  p u n k)]);
#$rslt = $calc->to_base(13933);
dig( [ qw(i  a m  v e r y  p u n k) ] ); 
#$rslt = cnv(13933, 10, 11); 
$rslt = cnv(13933, scalar( dig() )); # empty dig() returns the char array
&rprt($rslt eq 'krap', "$rslt\n");
#$calc->digits('hex');
#$rslt = $calc->to_base('-17');
dig('heX'); 
$rslt = heX(-17);
&rprt($rslt eq '-11', "$rslt\n");
#$calc->digits('hex');
#$rslt = $calc->from_base('-11');
dig('heX'); 
$rslt = dec(-11);
&rprt($rslt eq '-17', "$rslt\n");
# no usable fractions in b8 yet!  ...
#  $calc->digits('hex');
#  $rslt = $calc->from_base('-11.05');
#  &rprt($rslt eq '-17.01953125', "$rslt\n");
#  $calc->digits([0..6]);
#  $rslt = $calc->from_base('0.1');
#  &rprt($rslt eq (1/7), "$rslt\n");
# ... so do two more dig tests instead
dig( [ qw(i  a m  v e r y  p u n k) ] ); 
$rslt = cnv(13542, scalar( dig() )); 
&rprt($rslt eq 'kaka', "$rslt\n");
dig( [ qw( n a c h o z   y u m ) ] );
$rslt = cnv(lc('MunchYummyNachoChz'), 9, 10) / (10**17);
$rslt = substr($rslt, 0, 10);
&rprt($rslt eq '1.46443919', "$rslt\n");
# Test large numbers && dec/heX functions
#$calc->digits('hex');
#my $r1 = $calc->to_base(2**55 + 5);
#$rslt = $calc->from_base($calc->to_base(2**55 + 5));
#warn "res: $r1, $rslt";
dig('heX'); 
$calc =     heX(2**5 + 5);
$rslt = dec(heX(2**5 + 5));
&rprt($rslt eq (2**5 + 5), "$rslt\n");
#$calc->digits('bin');
#my $first  = $calc->from_base('1110111');
#my $second = $calc->from_base('1010110');
#my $third = $calc->to_base($first * $second);
dig('bin');
my $first  = cnv('1110111',           2, 10);
my $second = cnv('1010110',           2, 10);
my $third  = cnv(($first * $second),      2);
&rprt($third eq '10011111111010', "$third\n");
# Test b10/b64 functions
diginit();
$rslt = b64(1234567890); # 10 base10 digits is only 6 bass64 digits
&rprt($rslt eq '19bWBI', "$rslt\n");
$rslt = b10('TheBootyBoys.com') / (10**28); # Around The Corner =)
$rslt = substr($rslt, 0, 10);
&rprt($rslt eq '3.67441470', "$rslt\n");
$rslt = b10(b64(   127));
&rprt($rslt eq    '127', "$rslt\n");
$rslt = b10(b64(  4096));
&rprt($rslt eq   '4096', "$rslt\n");
$rslt = b10(b64( 65535));
&rprt($rslt eq  '65535', "$rslt\n");
$rslt = fact(3);
&rprt($rslt eq      '6', "$rslt\n");
$rslt = fact(4);
&rprt($rslt eq     '24', "$rslt\n");
$rslt = fact(7);
&rprt($rslt eq   '5040', "$rslt\n");
$rslt = fact(8);
&rprt($rslt eq  '40320', "$rslt\n");
$rslt = choo(7, 3);
&rprt($rslt eq     '35', "$rslt\n");
$rslt = choo(15, 7);
&rprt($rslt eq   '6435', "$rslt\n");
$rslt = choo(16, 8);
&rprt($rslt eq  '12870', "$rslt\n");
$rslt = choo(127, 3);
&rprt($rslt eq '333375', "$rslt\n");
$rslt = summ(7);
&rprt($rslt eq     '28', "$rslt\n");
$rslt = summ(8);
&rprt($rslt eq     '36', "$rslt\n");
$rslt = summ(15);
&rprt($rslt eq    '120', "$rslt\n");
$rslt = summ(127);
&rprt($rslt eq   '8128', "$rslt\n");
