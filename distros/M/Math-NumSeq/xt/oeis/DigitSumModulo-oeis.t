#!/usr/bin/perl -w

# Copyright 2012, 2020 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Math::BigInt;
use Test;
plan tests => 3;


use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::DigitSumModulo;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A019300 - Thue-Morse n bits as binary

MyOEIS::compare_values
  (anum => 'A019300',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::DigitSumModulo->new (radix => 2,
                                                  modulus => 2);
     my @got = map {A019300($_)} 1 .. $count;
     # my $result = Math::BigInt->new (0);
     # while (@got < $count) {
     #   my ($i, $value) = $seq->next;
     #   $result = 2*$result + $value;
     #   push @got, $result;
     # }
     return \@got;
   });

sub A019300 {
  my ($n) = @_;
  my $seq = Math::NumSeq::DigitSumModulo->new (radix => 2,
                                               modulus => 2);
  my $result = Math::BigInt->new (0);
  foreach (1 .. $n) {
    my ($i, $value) = $seq->next;
    $result = 2*$result + $value;
  }
  return $result;
}

# A048707 - Thue-Morse, 2^k bits as bignum
MyOEIS::compare_values
  (anum => 'A048707',
   func => sub {
     my ($count) = @_;
     return [ map {A019300(2**$_)} 0 .. $count-1 ];
   });


#------------------------------------------------------------------------------
# A133468 - Thue-Morse complement, 2^k bits as bignum

MyOEIS::compare_values
  (anum => 'A133468',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::DigitSumModulo->new (radix => 2,
                                                  modulus => 2);
     my $one = Math::BigInt->new(1);
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       $seq->rewind;
       my $result = Math::BigInt->new (0);
       foreach my $s (0 .. 2**$k-1) {
         my ($i, $value) = $seq->next;
         $result = ($result<<1) + (1-$value);
       }
       push @got, $result;
     }
     return \@got;
   });


#------------------------------------------------------------------------------

# Srecko Brlek, "Enumeration of Factors in the Thue-Morse Word", Discrete
# Applied Mathematics, volume 24, 1989, pages 83-96.

# GP-DEFINE  P_r_and_p(m) = m-=2; my(r=logint(m,2)); [r, m-2^r+1];
# GP-Test  for(m=3,2^10, \
# GP-Test    my(r,p); [r,p]=P_r_and_p(m); \
# GP-Test    m == 2^r + p + 1 || error("m=",m," but r=",r," p=",p); \
# GP-Test    p > 0 || error("m=",m," r=",r," p=",p); \
# GP-Test    p <= 2^r || error("m=",m," r=",r," p=",p); \
# GP-Test  ); 1
#
# GP-DEFINE  \\ factor complexity of the Thue-Morse word,
# GP-DEFINE  \\ num subwords of length m
# GP-DEFINE  \\ A005942
# GP-DEFINE  P(m) = {
# GP-DEFINE    my(r,p); [r,p]=P_r_and_p(m);
# GP-DEFINE    if(p <= 2^(r-1), 6*2^(r-1) + 4*p, 8*2^(r-1) + 2*p);
# GP-DEFINE  }
# vector(40,m,m+=2; P(m))
#
# vector(40,m,m+=2; P(m+1)-P(m))
# A214212 num right special factors

# GP-DEFINE  R_r_and_p(n) = n-=2; my(r=logint(n,2)); [r, n-2^r+2];
# GP-Test  for(n=3,2^10, \
# GP-Test    my(r,p); [r,p]=R_r_and_p(n); \
# GP-Test    n == 2^r + p || error("n=",n," but r=",r," p=",p); \
# GP-Test    p >= 2 || error("n=",n," r=",r," p=",p); \
# GP-Test    p <= 2^r+1 || error("n=",n," r=",r," p=",p); \
# GP-Test  ); 1
#
# GP-DEFINE  \\ recurrence index of the Thue-Morse word,
# GP-DEFINE  \\ Morse and Hedlund, "Symbolic Dynamics", Amer J Maths 60 1938 815-866
# GP-DEFINE  \\ A179867
# GP-DEFINE  R(n) = {
# GP-DEFINE    my(r,p); [r,p]=R_r_and_p(n);
# GP-DEFINE    10*2^r + p - 1;
# GP-DEFINE  }
# vector(40,n,n+=2; R(n))
#


#------------------------------------------------------------------------------
exit 0;
