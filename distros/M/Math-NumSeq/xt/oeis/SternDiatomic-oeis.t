#!/usr/bin/perl -w

# Copyright 2012, 2020, 2021 Kevin Ryde

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
use Test;
plan tests => 8;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::SternDiatomic;
use Math::NumSeq::Fibonacci;

# uncomment this to run the ### lines
# use Smart::Comments '###';

# GP-DEFINE  read("OEIS-data.gp");
# GP-DEFINE  read("memoize.gp");

#------------------------------------------------------------------------------
# Partitions into Fibonaccis

# GP-DEFINE  \\ A002487
# GP-DEFINE  Diatomic(n) = {
# GP-DEFINE    n>=0 || error();
# GP-DEFINE    my(p=0, q=1);
# GP-DEFINE    for(i=0,if(n,logint(n,2)), if(bittest(n,i),p+=q,q+=p));
# GP-DEFINE    p;
# GP-DEFINE  }
# GP-DEFINE  A002487(n) = Diatomic(n);
# GP-Test  my(v=OEIS_data("A002487"));  /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A002487(n)) == v

# GP-DEFINE  even_Fibs = Set(vector(20,n,fibonacci(2*n)));
# GP-DEFINE  \\ A103563
# GP-DEFINE  num_even_Fib_partitions(n) = {
# GP-DEFINE    my(ret=0);
# GP-DEFINE    forpart(v=n, if(#setminus(Set(v),even_Fibs)==0, ret++));
# GP-DEFINE    ret;
# GP-DEFINE  }
# vector(20,n, num_even_Fib_partitions(n))

# GP-DEFINE  Fibs = Set(vector(30,n,fibonacci(n)));
# GP-DEFINE  \\ A003107
# GP-DEFINE  num_Fib_partitions(n) = {
# GP-DEFINE    my(ret=0);
# GP-DEFINE    forpart(v=n, if(#setminus(Set(v),Fibs)==0, ret++));
# GP-DEFINE    ret;
# GP-DEFINE  }
# vector(20,n, num_Fib_partitions(n))

# GP-DEFINE  \\ A000119
# GP-DEFINE  num_distinct_Fib_partitions(n,k=1) = {
# GP-DEFINE    if(n==0,1,
# GP-DEFINE       Fibs[k]>n, 0,
# GP-DEFINE       num_distinct_Fib_partitions(n,k+1)
# GP-DEFINE       + num_distinct_Fib_partitions(n-Fibs[k],k+1));
# GP-DEFINE  }
# GP-DEFINE  num_distinct_Fib_partitions = memoize(num_distinct_Fib_partitions);
# GP-DEFINE  A000119(n) = num_distinct_Fib_partitions(n);
# GP-Test  my(v=OEIS_data("A000119"));  /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; num_distinct_Fib_partitions(n)) == v

# GP-DEFINE  num_distinct_Fib_partitions_by_parts(n) = {
# GP-DEFINE    my(ret=0);
# GP-DEFINE    forpart(v=n, my(s=Set(v)); if(#s==#v&&setminus(s,Fibs)==0, ret++));
# GP-DEFINE    ret;
# GP-DEFINE  }
# GP-Test  vector(40,n,num_distinct_Fib_partitions(n)) == \
# GP-Test  vector(40,n,num_distinct_Fib_partitions_by_parts(n))

# GP-DEFINE  \\ A054204 = integers as sum distinct even-index Fibs
# GP-DEFINE  \\ = bits as Fibonacci numbers F(2k+2)
# GP-DEFINE  my(m=Mod('x,'x^2-3*'x+1)); \
# GP-DEFINE  A054204(n) = subst(lift(subst(Pol(binary(n)), 'x,m)), 'x,3);
# GP-Test  my(v=OEIS_data("A054204")); /* OFFSET=1 */ \
# GP-Test    v == vector(#v,n, A054204(n))

# GP-Test  /* Marjorie Bicknell-Johnson */ \
# GP-Test  /* A054204 = integers as sum distinct even-index Fibs */ \
# GP-Test  /* Their num partitions into distinct any Fibs = Diatomic */ \
# GP-Test  my(v=OEIS_data("A054204"));  /* OFFSET=1 */ \
# GP-Test    vector(#v,n, num_distinct_Fib_partitions(v[n])) == \
# GP-Test    vector(#v,n, Diatomic(n+1))
# GP-Test  my(a=A002487); \
# GP-Test  vector(1000,n, a(n+1)) == \
# GP-Test  vector(1000,n, A000119(A054204(n)))


# my(v=OEIS_data("A054204")); apply(num_distinct_Fib_partitions,v[1..16])
#
# 1, 3, 4, 8, 9, 11, 12, 21, 22, 24, 25, 29, 30, 32, 33, 55, 56, 58, 59,

#------------------------------------------------------------------------------
# A052984 - sum diatomic^2 in row k of triangle
#
# R. P. Stanley, "Some Linear Recurrences Motivated by Stern's Diatomic Array",
# 2019, arxiv 1901.04647.
#
# A337277
# triangle first half each row is diatomic 1..2^k
# second half same in reverse
# 1 1 2 1 3 2 3 1 ...
# row 1 1 2 1 3 2 3 1 3 2 3 1 2 1 1

MyOEIS::compare_values
  (anum => 'A052984',
   max_count => 12,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::SternDiatomic->new;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       my $total = 0;
       foreach my $n (1 .. 2**$k) {
         ### ith: $seq->ith($n)
         $total += $seq->ith($n) ** 2;
       }
       push @got, 2*$total - 1;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A337277',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::SternDiatomic->new;
     my @got;
     OUTER: for (my $k = 0; @got < $count; $k++) {
       foreach my $n (1 .. 2**$k) {
         @got < $count or last OUTER;
         push @got, $seq->ith($n)
       }
       foreach my $n (reverse 1 .. 2**$k-1) {
         @got < $count or last OUTER;
         push @got, $seq->ith($n)
       }
     }
     return \@got;
   });

# GP-DEFINE  A337277_row(n) = {
# GP-DEFINE    my(v=[1],upto=0);
# GP-DEFINE    for(i=1,n,
# GP-DEFINE      my(new=vector(2*#v+1),upto=0);
# GP-DEFINE      new[upto++] = 1;
# GP-DEFINE      for(j=1,#v,
# GP-DEFINE        new[upto++] = v[j];
# GP-DEFINE        if(j<#v, new[upto++] = v[j] + v[j+1]));
# GP-DEFINE      new[upto++] = 1;
# GP-DEFINE      upto==#new || error();
# GP-DEFINE      v=new);
# GP-DEFINE    v;
# GP-DEFINE  }
# GP-Test  A337277_row(0) == [1]
# GP-Test  A337277_row(1) == [1,1,1]
# GP-Test  A337277_row(2) == [1, 1, 2, 1, 2, 1, 1]
# GP-Test  A337277_row(3) == [1, 1, 2, 1, 3, 2, 3, 1, 3, 2, 3, 1, 2, 1, 1]
# GP-Test  A337277_row(4) == [1, 1, 2, 1, 3, 2, 3, 1, 4, 3, 5, 2, 5, 3, 4, \
# GP-Test                     1, 4, 3, 5, 2, 5, 3, 4, 1, 3, 2, 3, 1, 2, 1, 1]
# GP-Test  my(v=OEIS_data("A337277"),got=[]); \
# GP-Test  my(n=0); while(#got<#v, got=concat(got,A337277_row(n)); n++); \
# GP-Test  v == got[1..#v]

# GP-DEFINE  A337277_T(n,k) = {
# GP-DEFINE    k<2^(n+1)-1 || error("n="n" k="k);
# GP-DEFINE    k++; k=min(k,2^(n+1)-k);
# GP-DEFINE    my(p=0,q=1);
# GP-DEFINE    forstep(i=logint(k,2),0,-1, if(bittest(k,i),p+=q,q+=p));
# GP-DEFINE    p;
# GP-DEFINE  }
# my(n=3); vector(2^(n+1)-1,k,k--; A337277_T(n,k))
# my(n=3); A337277_row(n)
# GP-Test  vector(8,n, vector(2^(n+1)-1,k,k--; A337277_T(n,k))) == \
# GP-Test  vector(8,n, A337277_row(n))

# GP-DEFINE  \\ code by MFH in A002487
# GP-DEFINE  A002487(n, a=1, b=0) = {
# GP-DEFINE    if(n==0,return(0));
# GP-DEFINE    for(i=0, logint(n, 2), if(bittest(n, i), b+=a, a+=b)); b;
# GP-DEFINE  }
# GP-Test  my(v=OEIS_data("A002487"));  /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A002487(n)) == v
#
# GP-Test  /* formula by Alois P. Heinz in A337277 */ \
# GP-Test  vector(100,n,n--; A337277_T(n,n)) == \
# GP-Test  vector(100,n,n--; A002487(n+1))
# GP-Test  A002487(0) == 0

# GP-Test  /* each row the diatomic sequence forward and backward */ \
# GP-Test  vector(8,n, A337277_row(n)) == \
# GP-Test  vector(8,n, vector(2^(n+1)-1,k,k--; \
# GP-Test    if(k<2^n, A002487(k+1), A002487(2^(n+1)-1-k))))


#------------------------------------------------------------------------------
# A071911 - where diatomic == 0 mod 3

MyOEIS::compare_values
  (anum => 'A071911',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::SternDiatomic->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value%3 == 0) { push @got, $i; }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A049455 - repeat runs diatomic 0 to 2^k

MyOEIS::compare_values
  (anum => 'A049455',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::SternDiatomic->new;
     my @got;
   OUTER: for (my $exp = 0; ; $exp++) {
       foreach my $i (0 .. 2**$exp) {
         last OUTER if @got >= $count;
         push @got, $seq->ith($i);
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A049456 - extra 1 at end of each row

MyOEIS::compare_values
  (anum => 'A049456',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::SternDiatomic->new;
     my @got;
     $seq->next;
     for (;;) {
       my ($i,$value) = $seq->next;
       last if @got >= $count;
       push @got, $value;
       if ($i > 1 && is_pow2($i)) {
         last if @got >= $count;
         push @got, 1;
       }
     }
     return \@got;
   });


sub is_pow2 {
  my ($n) = @_;
  return ($n & ($n-1)) == 0;
}

#------------------------------------------------------------------------------
# A126606 - starting 0,2 so double of Stern diatomic

MyOEIS::compare_values
  (anum => 'A126606',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::SternDiatomic->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value*2;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A061547 - position of Fibonacci F[n],F[n+1] in Stern diatomic
#
# Stern: 0,1,1,2,1,3,2,3,1,4,3,5,2,5,3,4,1,5,4,7,3,
#            ^       ^       ^
#           i=2     i=6     i=10

MyOEIS::compare_values
  (anum => 'A061547',
   max_value => 1_000_000,
   func => sub {
     my ($count) = @_;
     my $stern = Math::NumSeq::SternDiatomic->new;
     my $fib = Math::NumSeq::Fibonacci->new;
     my ($i, $fprev) = $fib->next;
     my ($j, $fvalue) = $fib->next;
     my ($k, $sprev) = $stern->next;
     my @got;
     while (@got < $count) {
       my ($i, $svalue) = $stern->next;
       ### at: "stern $sprev,$svalue seeking $fprev,$fvalue"
       if ($sprev == $fprev
           && $svalue == $fvalue) {
         ### found: "$fvalue,$fprev at i=$i"
         push @got, $i - 1;
         $fprev = $fvalue;
         (undef, $fvalue) = $fib->next;
       }
       $sprev = $svalue;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A086893 - position of Fibonacci F[n+1],F[n] in Stern diatomic
#
# Stern: 0,1,1,2,1,3,2,3,1,4,3,5,2,5,3,4,1,5,4,7,3,
#              ^   ^               ^
#             i=3 i=5             i=13

MyOEIS::compare_values
  (anum => 'A086893',
   max_value => 1_000_000,
   func => sub {
     my ($count) = @_;
     my $stern = Math::NumSeq::SternDiatomic->new;
     my $fib = Math::NumSeq::Fibonacci->new;
     $fib->next;    # skip 0
     my (undef, $fprev) = $fib->next;
     my (undef, $fvalue) = $fib->next;
     my (undef, $sprev) = $stern->next;
     my @got;
     while (@got < $count) {
       my ($i, $svalue) = $stern->next;
       ### at: "stern $sprev,$svalue seeking $fprev,$fvalue"
       if ($sprev == $fvalue
           && $svalue == $fprev) {
         ### found: "$fvalue,$fprev at i=$i"
         push @got, $i - 1;
         $fprev = $fvalue;
         (undef, $fvalue) = $fib->next;
       }
       $sprev = $svalue;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
