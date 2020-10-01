#!/usr/bin/perl -w

# Copyright 2012, 2013, 2018, 2020 Kevin Ryde

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
use Test;
plan tests => 12;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::ZOrderCurve;
use Math::PlanePath::Diagonals;

# GP-DEFINE  read("my-oeis.gp");


#------------------------------------------------------------------------------
# A057300 -- self-inverse permutation N at transpose Y,X, radix=2
# A163327 -- N at transpose Y,X, radix=3
# A126006 -- N at transpose Y,X, radix=4
# A217558 -- N at transpose Y,X, radix=16, conceived as 1-byte nibble swap

# more bases
# not in OEIS: 5,10,15,20,1,6,11,16,21,2,7,12,17
# not in OEIS: 6,12,18,24,30,1,7,13,19,25,31,2,8
# not in OEIS: 7,14,21,28,35,42,1,8,15,22,29,36
# not in OEIS: 8,16,24,32,40,48,56,1,9,17,25,33
# not in OEIS: 9,18,27,36,45,54,63,72,1,10,19,28
# not in OEIS: 10,20,30,40,50,60,70,80,90,1,11,21,31,41,51,61,71,81,91

foreach my $elem (['A057300', 2],
                  ['A163327', 3],
                  ['A126006', 4],
                  ['A217558', 16],
                 ) {
  my ($anum,$radix) = @$elem;

  MyOEIS::compare_values
      (anum => $anum,
       func => sub {
         my ($count) = @_;
         my @got;
         my $path = Math::PlanePath::ZOrderCurve->new (radix => $radix);
         for (my $n = $path->n_start; @got < $count; $n++) {
           my ($x, $y) = $path->n_to_xy ($n);
           ($x, $y) = ($y, $x);
           my $n = $path->xy_to_n ($x, $y);
           push @got, $n;
         }
         return \@got;
       });
}

# A126007 - base 4 low digit fixed, X <-> Y flips above there
MyOEIS::compare_values
  (anum => q{A126007},  # not much path interpretation
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::ZOrderCurve->new (radix => 4);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my $low = $n & 3;
       my ($x,$y) = $path->n_to_xy ($n >> 2);
       my $high = $path->xy_to_n ($y,$x);
       push @got, ($high << 2) + $low;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163325 -- radix=3 X coordinate

MyOEIS::compare_values
  (anum => q{A163325},  # catalogued too
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::ZOrderCurve->new (radix => 3);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $x;
     }
     return \@got;
   });

# A163326 -- radix=3 Y coordinate
MyOEIS::compare_values
  (anum => q{A163326},  # catalogued too
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::ZOrderCurve->new (radix => 3);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $y;
     }
     return \@got;
   });

# GP-DEFINE  \\ extract ternary digit k of n
# GP-DEFINE  A030341(n,k) = (n\3^k)%3;
#
# GP-DEFINE  \\ powers of 3 alternating with 0s
# GP-DEFINE  A254006(n) = if(n%2==0, 3^(n/2), 0);
# my(v=OEIS_samples("A254006")); vector(#v,n,n--; A254006(n)) == v  \\ OFFSET=0
# my(g=OEIS_bfile_gf("A254006")); g==Polrev(vector(poldegree(g)+1,n,n--;A254006(n)))
# poldegree(OEIS_bfile_gf("A254006"))
#
# GP-DEFINE  A163325(n) = fromdigits(digits(n, 9)%3, 3); \\ mine
#
# GP-Test  /* Philippe Deleham in A163325 */ \
# GP-Test  my(b=A254006); \
# GP-Test  vector(3^6,n,n--; A163325(n)) == \
# GP-Test  vector(3^6,n,n--; sum(k=0,if(n,logint(n,3)), A030341(n,k)*b(k)))


#------------------------------------------------------------------------------
# A163328 -- radix=3 zorder N of an x,y point in diagonals order, same axis

MyOEIS::compare_values
  (anum => 'A163328',
   func => sub {
     my ($count) = @_;
     my @got;
     my $zorder   = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up',
                                                     n_start => 0);
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $zorder->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A163329 -- radix=3 diagonals N of an x,y point in zorder
# inverse perm of A163328
MyOEIS::compare_values
  (anum => 'A163329',
   func => sub {
     my ($count) = @_;
     my @got;
     my $zorder   = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up',
                                                     n_start => 0);
     for (my $n = $zorder->n_start; @got < $count; $n++) {
       my ($x, $y) = $zorder->n_to_xy ($n);
       push @got, $diagonal->xy_to_n ($x, $y);
     }
     return \@got;
   });

# GP-DEFINE  A163328(n) = {
# GP-DEFINE     my(d=(sqrtint(8*n+1)-1)\2); n -= d*(d+1)/2;
# GP-DEFINE     subst(Pol(3*digits(n,3)) + Pol(digits(d-n,3)),'x,9);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A163328")); v == vector(#v,n,n--; A163328(n))
# GP-Test  my(g=OEIS_bfile_gf("A163328")); g==Polrev(vector(poldegree(g)+1,n,n--;A163328(n)))
# poldegree(OEIS_bfile_gf("A163328"))
# vector(20,n,n--; A163328(n))
# OEIS_samples("A163328")

# GP-Test  my(x,y); vector(9,n,n--; [y,x]=divrem(n,3); x+y) == \
# GP-Test           [0,1,2, 1,2,3, 2,3,4]
# GP-Test  my(x,y); vector(9,n,n--; [y,x]=divrem(n,3); x+3*y) == \
# GP-Test           [0..8]
# GP-DEFINE  { my(table=[0,1,2, 1,2,3, 2,3,4]);
# GP-DEFINE    A163329(n) = my(v=digits(n,9)); 
# GP-DEFINE     ( fromdigits(apply(d->table[d+1],v),3)^2
# GP-DEFINE     + fromdigits(v,3) )/2;
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A163329")); v == vector(#v,n,n--; A163329(n))
# GP-Test  my(g=OEIS_bfile_gf("A163329")); g==Polrev(vector(poldegree(g)+1,n,n--;A163329(n)))
# poldegree(OEIS_bfile_gf("A163329"))
# vector(20,n,n--; A163329(n))


#------------------------------------------------------------------------------
# A163330 -- radix=3 diagonals opposite axis

MyOEIS::compare_values
  (anum => 'A163330',
   func => sub {
     my ($count) = @_;
     my @got;
     my $zorder   = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down',
                                                     n_start => 0);
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $zorder->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A163331 -- radix=3 diagonals same axis, inverse
MyOEIS::compare_values
  (anum => 'A163331',
   func => sub {
     my ($count) = @_;
     my @got;
     my $zorder   = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down',
                                                     n_start => 0);
     for (my $n = $zorder->n_start; @got < $count; $n++) {
       my ($x, $y) = $zorder->n_to_xy ($n);
       push @got, $diagonal->xy_to_n ($x, $y);
     }
     return \@got;
   });

# GP-DEFINE  A163330(n) = {
# GP-DEFINE     my(d=(sqrtint(8*n+1)-1)\2); n -= d*(d+1)/2;
# GP-DEFINE     subst(Pol(digits(n,3)) + Pol(3*digits(d-n,3)),'x,9);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A163330")); v == vector(#v,n,n--; A163330(n))
# GP-Test  my(g=OEIS_bfile_gf("A163330")); g==Polrev(vector(poldegree(g)+1,n,n--;A163330(n)))
# poldegree(OEIS_bfile_gf("A163330"))
# vector(20,n,n--; A163330(n))
# OEIS_samples("A163330")

# GP-Test  my(x,y); vector(9,n,n--; [y,x]=divrem(n,3); x+y) == \
# GP-Test           [0,1,2, 1,2,3, 2,3,4]
# GP-Test  my(x,y); vector(9,n,n--; [y,x]=divrem(n,3); 3*x+y) == \
# GP-Test           [0,3,6, 1,4,7, 2,5,8]
# GP-DEFINE  { my(table1=[0,1,2, 1,2,3, 2,3,4],
# GP-DEFINE       table2=[0,3,6, 1,4,7, 2,5,8]);
# GP-DEFINE    A163331(n) = my(v=digits(n,9)); 
# GP-DEFINE     ( fromdigits([table1[d+1]|d<-v],3)^2
# GP-DEFINE     + fromdigits([table2[d+1]|d<-v],3) )/2;
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A163331")); v == vector(#v,n,n--; A163331(n))
# GP-Test  my(g=OEIS_bfile_gf("A163331")); g==Polrev(vector(poldegree(g)+1,n,n--;A163331(n)))
# poldegree(OEIS_bfile_gf("A163331"))
# vector(20,n,n--; A163331(n))


#------------------------------------------------------------------------------
# A054238 -- permutation, binary, diagonals same axis

MyOEIS::compare_values
  (anum => 'A054238',
   func => sub {
     my ($count) = @_;
     my @got;
     my $zorder   = Math::PlanePath::ZOrderCurve->new;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up',
                                                     n_start => 0);
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $zorder->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A054239 -- diagonals same axis, binary, inverse
MyOEIS::compare_values
  (anum => 'A054239',
   func => sub {
     my ($count) = @_;
     my @got;
     my $zorder   = Math::PlanePath::ZOrderCurve->new;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up',
                                                     n_start => 0);
     for (my $n = $zorder->n_start; @got < $count; $n++) {
       my ($x, $y) = $zorder->n_to_xy ($n);
       push @got, $diagonal->xy_to_n ($x, $y);
     }
     return \@got;
   });


#------------------------------------------------------------------------------

exit 0;
