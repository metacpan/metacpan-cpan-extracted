#!/usr/bin/perl -w

use Test;
BEGIN { plan tests => 17; }

use lib '../lib';                               # comment out to use old module
#use lib '../../old/Math-BigInt-0.01/lib';      # for old version

use strict;
#use Math::BigInt;
use Math::BigInt qw/:constant/;
#use Math::BigInt qw/calc BitVect :constant/;

print "# Using Math::BigInt v",$Math::BigInt::VERSION,"\n";

# calculate some sample prime numbers from
# http://www.utm.edu/research/primes/largest.html
# also: http://www-stud.enst.fr/~bellard/mersenne.html
# (c takes 1 minute on 800 Mhz, so Perl will take..ages..)

my ($x,$y,$z);
my $two = Math::BigInt->new(2);

# some new() are to make stop Perl from calculating things like 1234 ** 4321
# at compile time. (we want to see run-time behaviour)
# Also there is len(), since the old BigInt has not got length() and we want
# this script to be comparable between old and new version.

##############################################################################
# Todo: these do not complete in reasonable time:

# $x = $two ** 6972593; $x--;    #ok (len($x),'2098960');
# $x = $two ** 3021377; $x--;    #ok (len($x),'909526');
# $x = $two ** 756839; $x--;     #ok (len($x),'227832');
# $x = 1041870 ** 32768; $x++;   #ok (len($x),'197192');

##############################################################################
# but these do:

# some twin primes (first in list at 03/2001)
$x = ($two ** 80025) * 665551035; $x++; $y = $x-2; ok (len($x),'24099');
$x = ($two ** 66443) * 1693965; $x++; $y = $x-2;   ok (len($x),'20008');
$x = ($two ** 64955) * 83475759; $x++; $y = $x-2;  ok (len($x),'19562');
# ...
$x = ($two ** 38880) * 242206083; $x++; $y = $x-2; ok (len($x),'11713');

##############################################################################
# Sophie Germain primes
# todo: does not finish after 30 m on 800 Mhz

# $x = Math::BigInt->new(72021)**223630; $x--; ok (len($x),'7119');

##############################################################################
# some quadruplet primes...

# 3510160221387831655*(2^3363-2^1121)-6*2^1121-7
$x = '3510160221387831655' * (2 ** 3363 - 2**1121) - 6*(2**1121);
my @q = ( $x-7,$x-5,$x-1,$x+1);
ok (len($q[0]),'1031');
ok (len($q[1]),'1031');
ok (len($q[2]),'1031');
ok (len($q[3]),'1031');

##############################################################################
# some real weird primes:

# (2^3833-1)/(14193959303*340789152474053904109001)
$x = Math::BigInt->new('340789152474053904109001');
$x *= '14193959303';
$x = (2**3833-1) / $x;
ok (len($x),'1121');

#(2^4751-1)/(268982617*3274778783*629530076753*81630665742097*1507074535068001)
$x = Math::BigInt->new('268982617');
$x = $x * '3274778783' * '629530076753' * '81630665742097' * '1507074535068001';
$x = ((2**4751)-1) / $x;
ok (len($x),'1372');

# 2^7039-1)/ (1252943*1057032553*8541573097*218216841131937276721
$x = Math::BigInt->new('1252943')*'1057032553'*'8541573097';
$x *= '218216841131937276721';
$x = ((2**7039)-1) / $x;
ok (len($x),'2074');

# 5616^1153-1)/5615
$x = Math::BigInt->new(5616) ** 1153; $x--; $x /= 5616;
ok (len($x),'4320');

# (7147^2161-1)/7146
$x = Math::BigInt->new(7147) ** 2161; $x--; $x /= 7146;
ok (len($x),'8325');

# 16*R(5700)*(150093*10^8000+1)+1 # most ending 7's
# gives error in BigInt
$x = 16 * R(5700);
$x *= (150093*(Math::BigInt->new(10)**8000))+1; $x++;
ok (len($x),'13706');

# 2*11^13359+1
$x = 2*(Math::BigInt->new(11)**13359)+1;
ok(len($x),'13913');

# 10^14800+5*(10^8880+10^5920)+7*10^7400+1
# palindrome
$x = Math::BigInt->new(10) ** 14800;
$x += 5*((Math::BigInt->new(10) ** 8800) + (Math::BigInt->new(10)**5920));
$x += 7*(Math::BigInt->new(10) ** 7400);
ok(len($x),'14801');

$y = "$x"; $y =~ s/^\+//;
my $left = substr("$y",7400);
my $right = substr("$y",-7401);
ok($left,$right);

# EOF

##############################################################################
# some helper functions

sub R
  {
  my $x = shift;
  # These numbers have a decimal expansion of n '1's,
  # and are usually called "repunits".
  return ((Math::BigInt->new(10) ** $x) - 1)/9;
  }

sub len
  {
  # old bigint has not got length, so use "" and strip it's sign
  my $x = shift;
  $x = "$x"; $x =~ s/^\+//;
  return length($x);
  }
