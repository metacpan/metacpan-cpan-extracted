#!/usr/bin/perl -w

# Copyright 2012, 2013, 2018, 2019, 2020 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Math::BigInt;
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099

use Test;
plan tests => 12;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::GrayCode;
use Math::PlanePath::Diagonals;

use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
use Math::PlanePath::Diagonals;

# GP-DEFINE  read("my-oeis.gp");

sub to_binary_gray {
  my ($n, $radix) = @_;
  my $digits = [ digit_split_lowtohigh($n,2) ];
  Math::PlanePath::GrayCode::_digits_to_gray_reflected($digits,2);
  return digit_join_lowtohigh($digits,2);
}


#------------------------------------------------------------------------------
# A195467 -- rows of Gray permutations by bit widths
# (for a time it had been array by anti-diagonals something)

# n bits is A062383(n-1) different rows, next strictly higher power of 2

MyOEIS::compare_values
  (anum => 'A195467',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $bits = 0; @got < $count; $bits++) {
       my @row = (0 .. 2**(2**$bits) - 1);
       foreach (1 .. 2**$bits) {
         push @got, @row;
         @row = map {to_binary_gray($_)} @row;
       }
     }
     $#got = $count-1;
     return \@got;
   });


#------------------------------------------------------------------------------
# A048641 - binary Gray cumulative sum

MyOEIS::compare_values
  (anum => 'A048641',
   func => sub {
     my ($count) = @_;
     my @got;
     my $cumulative = 0;
     for (my $n = 0; @got < $count; $n++) {
       $cumulative += to_binary_gray($n);
       push @got, $cumulative;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A048644 - binary Gray cumulative sum difference from triangular(n)

MyOEIS::compare_values
  (anum => 'A048644',
   func => sub {
     my ($count) = @_;
     my @got;
     my $cumulative = 0;
     for (my $n = 0; @got < $count; $n++) {
       $cumulative += to_binary_gray($n);
       push @got, $cumulative - triangular($n);
     }
     return \@got;
   });

sub triangular {
  my ($n) = @_;
  return $n*($n+1)/2;
}

#------------------------------------------------------------------------------
# A048642 - binary gray cumulative product

MyOEIS::compare_values
  (anum => 'A048642',
   func => sub {
     my ($count) = @_;
     my @got;
     my $product = Math::BigInt->new(1);
     for (my $n = 0; @got < $count; $n++) {
       $product *= (to_binary_gray($n) || 1);
       push @got, $product;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A048643 - binary gray cumulative product, diff to factorial(n)

MyOEIS::compare_values
  (anum => 'A048643',
   func => sub {
     my ($count) = @_;
     my @got;
     my $factorial = Math::BigInt->new(1);
     my $product   = Math::BigInt->new(1);
     for (my $n = 0; @got < $count; $n++) {
       $product *= (to_binary_gray($n) || 1);
       $factorial *= ($n||1);
       push @got, $product - $factorial;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A143329 - Gray(prime(n)) which is prime too

MyOEIS::compare_values
  (anum => 'A143329',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       next unless is_prime($n);
       my $gray = to_binary_gray($n);
       next unless is_prime($gray);
       push @got, $gray;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A143292 - binary Gray of primes

MyOEIS::compare_values
  (anum => 'A143292',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       next unless is_prime($n);
       push @got, to_binary_gray($n);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A005811 - count 1 bits in Gray(n), is num runs

MyOEIS::compare_values
  (anum => 'A005811',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $gray = to_binary_gray($n);
       push @got, count_1_bits($gray);
     }
     return \@got;
   });

sub count_1_bits {
  my ($n) = @_;
  my $count = 0;
  while ($n) {
    $count += ($n & 1);
    $n >>= 1;
  }
  return $count;
}


#------------------------------------------------------------------------------
# A173318 - cumulative count 1 bits in gray(n) ie. of A005811

MyOEIS::compare_values
  (anum => 'A173318',
   func => sub {
     my ($count) = @_;
     my @got;
     my $cumulative = 0;
     for (my $n = 0; @got < $count; $n++) {
       $cumulative += count_1_bits(to_binary_gray($n));
       push @got, $cumulative;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A099891 -- triangle cumulative XOR Grays

#  0,
#  1, 1,
#  3, 2, 3,
#  2, 1, 3, 0,
#  6, 4, 5, 6, 6,
#  7, 1, 5, 0, 6, 0,
#  5, 2, 3, 6, 6, 0, 0,
#  4, 1, 3, 0, 6, 0, 0, 0,
# 12, 8, 9,10,10,12,12,12,12,...
# first column Gray codes, then pairs xored by
#     A
#     B  A^B
# binomial mod 2 count of whether each Gray net odd or even into an entry

MyOEIS::compare_values
  (anum => 'A099891',
   func => sub {
     my ($count) = @_;
     my @got;
     my @array;
     for (my $y = 0; @got < $count; $y++) {
       my $gray = to_binary_gray($y);
       push @array, [ $gray ];
       for (my $x = 1; $x <= $y; $x++) {
         $array[$y][$x] = $array[$y-1][$x-1] ^ $array[$y][$x-1];
       }
       for (my $x = 0; $x <= $y && @got < $count; $x++) {
         push @got, $array[$y][$x];
       }
     }
     return \@got;
   });

# GP-DEFINE  LowOneBit(n) = 1<<valuation(n,2);
# GP-DEFINE  A006519(n) = LowOneBit(n);
# GP-Test  my(v=OEIS_samples("A006519")); \
# GP-Test  v == vector(#v,n, A006519(n))  /* OFFSET=1 */
#
# GP-DEFINE  Gray(n) = bitxor(n,n>>1);
# GP-Test  my(v=OEIS_samples("A003188")); \
# GP-Test  v == vector(#v,n,n--; Gray(n))  /* OFFSET=0 */

# GP-DEFINE  A099891(n,k) = my(B=0); for(i=0,k, if(binomial(k,i)%2, B=bitxor(B,Gray(n-i)))); B;
# GP-Test  my(v=OEIS_samples("A099891"),l=List()); \
# GP-Test  for(n=0,#v, for(k=0,n, if(#l>=#v,break(2)); listput(l,A099891(n,k)))); \
# GP-Test  v == Vec(l)

#--
# second column k=1
# GP-Test  /* my formula */ \
# GP-Test  vector(256,n, A099891(n,1)) == \
# GP-Test  vector(256,n, A006519(n))

# GP-Test  vector(256,n, A099891(n,1)) == \
# GP-Test  vector(256,n,   bitxor(Gray(n),Gray(n-1)))
# GP-Test  vector(256,n, A099891(n,1)) == \
# GP-Test  vector(256,n,   bitxor(bitxor(n,n-1), bitxor(n,n-1)>>1))
# GP-Test  /* bitxor(n,n-1) changed bits by increment */ \
# GP-Test  vector(256,n, bitxor(n,n-1)) == \
# GP-Test  vector(256,n,   2*LowOneBit(n)-1)
# GP-Test  vector(256,n, bitxor(n,n-1)>>1) == \
# GP-Test  vector(256,n,   LowOneBit(n)-1)
#
# GP-Test  vector(256,n, A099891(n,1)) == \
# GP-Test  vector(256,n,   Gray(2*LowOneBit(n)-1))



#
# GP-Test  my(v=OEIS_samples("A099892")); v == vector(#v,n,n--; A099891(n,n))

# Sierpinski triangle patterns of each bit, until 0s past column 2^k
#
# for(n=0,64, for(k=0,n, printf(" %2d",A099891(n,k))); print());
# for(n=0,20, for(k=0,n, printf(" %d",A099891(n,k)%2)); print());
# for(n=0,64, for(k=0,n, printf(" %s",if(bitand(A099891(n,k),8),8,"."))); print());

# vector(20,n,n++; A099891(n,n-1))
# not in OEIS: 2, 3, 6, 6, 0, 0, 12, 12, 0, 0, 0, 0, 0, 0, 24, 24, 0, 0, 0, 0
# vector(20,n,n++; A099891(n,2))
# not in OEIS: 3, 3, 5, 5, 3, 3, 9, 9, 3, 3, 5, 5, 3, 3, 17, 17, 3, 3, 5, 5


#------------------------------------------------------------------------------
# A064706 - binary Gray twice
# which is n XOR n>>2

MyOEIS::compare_values
  (anum => 'A064706',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, to_binary_gray(to_binary_gray($n));
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A055975 - binary Gray increments

MyOEIS::compare_values
  (anum => 'A055975',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, to_binary_gray($n+1) - to_binary_gray($n);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
