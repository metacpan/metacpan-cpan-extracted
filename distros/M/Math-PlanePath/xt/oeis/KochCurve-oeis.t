#!/usr/bin/perl -w

# Copyright 2012, 2013, 2015, 2018, 2019, 2020, 2021 Kevin Ryde

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
plan tests => 22;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::KochCurve;
use Math::NumSeq::PlanePathDelta;
use Math::NumSeq::PlanePathTurn;

my $path = Math::PlanePath::KochCurve->new;

# GP-DEFINE  read("my-oeis.gp");


#------------------------------------------------------------------------------
# A332206 -- N on X axis

MyOEIS::compare_values
  (anum => 'A332206',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 0; @got < $count; $x++) {
       if (defined(my $n = $path->xy_to_n($x,0))) {
         push @got, $n;
       }
     }
     return \@got;
   });

# A001196 -- N segments on X axis, so N and N+1 points both on X axis
# Segment N=0 on axis, then on expansion must new low base 4 digit 0 or 3.
# All other segments leave the X axis and never return.
# So all base 4 digits 0,3, which is binary 00 11
MyOEIS::compare_values
  (anum => 'A001196',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 0; @got < $count; $x++) {
       if (defined(my $n = $path->xyxy_to_n($x,0, $x+2,0))) {
         push @got, $n;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A335358 -- (X-Y)/2 coordinate, at 60 degrees

MyOEIS::compare_values
  (anum => 'A335358',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, ($x-$y)/2;
     }
     return \@got;
   });

# A335359 -- Y coordinate
MyOEIS::compare_values
  (anum => 'A335359',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y;
     }
     return \@got;
   });

# pos  0, 1, 1+w6, 2,   3
# rot  0, 1, -1, 0
#
# GP-DEFINE  w = quadgen(-3);
# GP-Test  (w-1/2)^2 == -3/4
# arg(w)*180/Pi 
#
# pos_table = [0,1,1+w,2];
# rot_table = [1,w,conj(w),1];
# GP-DEFINE  my(table = [[1,0], [w,1], [conj(w),1+w], [1,2]]); \
# GP-DEFINE  Z(n) = {
# GP-DEFINE    my(v=digits(n,4),rot=1);
# GP-DEFINE    for(i=1,#v, [rot,v[i]] = rot*table[v[i]+1]);
# GP-DEFINE    subst(Pol(v),'x,3);
# GP-DEFINE  }
# Z(1)
# vector(12,n,n--; Z(n))
# OEIS_samples("A335358")
# GP-Test  my(v=OEIS_samples("A335358")); v==vector(#v,n,n--; real(Z(n)))
# GP-Test  my(v=OEIS_samples("A335359")); v==vector(#v,n,n--; imag(Z(n)))

# GP-DEFINE  { my(w=quadgen(-3), table=[[1,0], [w,1], [conj(w),1+w], [1,2]]);
# GP-DEFINE  X(n) =
# GP-DEFINE    my(v=digits(n,4),rot=1);
# GP-DEFINE    for(i=1,#v, [rot,v[i]] = rot*table[v[i]+1]);
# GP-DEFINE    fromdigits(real(v),3);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A335358")); v==vector(#v,n,n--; X(n))
# GP-Test  my(g=OEIS_bfile_gf("A335358")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--; X(n)))

# GP-DEFINE  { my(w=quadgen(-3), table=[[1,0], [w,1], [conj(w),1+w], [1,2]]);
# GP-DEFINE  Y(n) =
# GP-DEFINE    my(v=digits(n,4),rot=1);
# GP-DEFINE    for(i=1,#v, [rot,v[i]] = rot*table[v[i]+1]);
# GP-DEFINE    fromdigits(imag(v),3);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A335359")); v==vector(#v,n,n--; Y(n))
# GP-Test  my(g=OEIS_bfile_gf("A335359")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--; Y(n)))

# GP-DEFINE  \\ 0,2,3 mod 6
# GP-DEFINE  A047244(n) = 2*n - (n%3==2);
# GP-Test  my(v=OEIS_samples("A047244")); v==vector(#v,n,n--; A047244(n))
#
# GP-Test  /* Andrey Zabolotskiy in A335359 */ \
# GP-Test  vector(4^6,n,n--; X(n)) == \
# GP-Test  vector(4^6,n,n--; Y(n) + Y(A047244(n)))
# GP-Test  vector(4^6,n,n--; Y(A047244(n))) == \
# GP-Test  vector(4^6,n,n--; X(n)-Y(n))
# GP-Test  vector(4^6,n,n--; Y(2*n)) == \
# GP-Test  vector(4^6,n,n--; X(n)-Y(n))
# GP-Test  X(4) == 3
# GP-Test  Y(4) == 0
# GP-Test  Y(A047244(4)) == 3
# vector(20,n,n--; A047244(n))

# vector(20,n,n--; X(n)-Y(n))
# not in OEIS: 0, 1, 0, 2, 3, 2, 0, 1, 0, 2, 3, 4, 6, 7, 6, 8, 9, 8, 6, 7
# vector(20,n,n--; Y(2*n))
# not in OEIS: 0, 1, 0, 2, 3, 2, 0, 1, 0, 2, 3, 4, 6, 7, 6, 8, 9, 8, 6, 7
# vector(20,n,n--; Y(2*n))
# vector(20,n,n--; Y(2*n))

# vector(20,n,n--; X(2*n))
# not in OEIS: 0, 1, 3, 2, 3, 5, 6, 7, 9, 8, 9, 7, 6, 7, 9, 8, 9, 11, 12, 13
# vector(50,n, X(n)-X(n-1))
# not in OEIS: 1, 0, 1, 1, 0, -1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, -1, 1, 0, -1, -1, 0, -1, 1, 0, 1, 1, 0, -1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, -1, 0, 1, 1, 0, 1, 1, 0

# GP-DEFINE  dY(n) = Y(n+1) - Y(n);
# vector(20,n, dY(2*n-1))
# not in OEIS: 1, 0, 1, 1, 0, -1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, -1, 1, 0
# turn 1, -2, 1

# for(k=200,210, print(digits(6*k + 3,4)))

# GP-DEFINE  w6 = quadgen(-3);
# GP-DEFINE  w3 = w6 - 1;
# GP-DEFINE  w12_times_sqrt3 = quadgen(-3) + 1;
# GP-Test  w12_times_sqrt3^6 == - 3^(6/2)
# GP-DEFINE  Z(n) = X(n) + Y(n)*w6;
# GP-Test  vector(4^6,n, conj(Z(2*n) / w12_times_sqrt3)) == \
# GP-Test  vector(4^6,n, Z(n))

# GP-Test  vector(4^6,n, X(n)+Y(n) + w3*Y(n)) == \
# GP-Test  vector(4^6,n, Z(n))
# GP-Test  vector(4^6,n, X(n)-Y(n) + (w6+1)*Y(n)) == \
# GP-Test  vector(4^6,n, Z(n))

# z = x + w6*y
#   = x + (w3+1)*y
#   = x + w3*y + y
#   = x+y + w3*y
#   = x-y + (w6+1)*y   basis 1, w6+1 at 30 degrees length sqrt3

#-------------
# X+Y
# vector(20,n,n--; X(n)+Y(n))
# not in OEIS: 0, 1, 2, 2, 3, 4, 4, 5, 6, 6, 7, 6, 6, 7, 8, 8, 9, 10, 10, 11

# GP-DEFINE  \\ curve  0---1   3---*
# GP-DEFINE  \\             \ /
# GP-DEFINE  \\              2
# GP-DEFINE  { my(w=quadgen(-3), table=[[1,0], [conj(w),1], [w,2-w], [1,2]]);
# GP-DEFINE  X120(n) =
# GP-DEFINE    my(v=digits(n,4),rot=1);
# GP-DEFINE    for(i=1,#v, [rot,v[i]] = rot*table[v[i]+1]);
# GP-DEFINE    fromdigits(real(v),3);
# GP-DEFINE  }
# GP-Test  vector(4^6,n,n--; X120(n)) == \
# GP-Test  vector(4^6,n,n--; X(n) + Y(n))

#-------------
# X-Y
# vector(20,n,n--; X(n)-Y(n))
# 0, 1, 0, 2,   3, 2, 0, 1,   0, 2, 3, 4
#               0 -1 -3 -2
#      Y
#     /
#    /
#   *-----X

# GP-DEFINE  { my(w=quadgen(-3), table=[[1,0], [w,1], [conj(w),1+w], [1,2]]);
# GP-DEFINE  XYdiff(n) =
# GP-DEFINE    my(v=digits(n,4),rot=1);
# GP-DEFINE    for(i=1,#v, [rot,v[i]] = rot*table[v[i]+1]);
# GP-DEFINE    fromdigits(imag(conj(v)),3);
# GP-DEFINE  }
# vector(46,n,n--; XYdiff(n))  \\ like A335359 Y coord
# vector(16,n,n--; X(n) - Y(n))
# vector(16,n,n--; X(n) + Y(n))  \\ like A335380 X coord
# not in OEIS: 0, 1, 0, 2, 3, 2, 0, 1, 0, 2, 3, 4, 6, 7, 6, 8

# my(w=quadgen(-3), table=[[1,0], [w,1], [conj(w),1+w], [1,2]]); \
# for(c=0,1, my(table=if(c,conj(table),table)); \
#   for(r=0,5, my(table=table*w^r); \
#     my(f=(n)-> my(v=digits(n,4),rot=1); \
#                for(i=1,#v, [rot,v[i]] = rot*table[v[i]+1]); \
#                fromdigits(real(v),3)); \
#     print(vector(16,n,n--; f(n)))))
#
# w=quadgen(-3)
# for(r=0,5, print(imag(('x-'y*w)*w^r)))


#------------------------------------------------------------------------------
# Cf wave-like at high resoluation
#
#         *
#       / |         Kochawave
#      /  |
# *---*   *---*
# my(g=OEIS_bfile_gf("A335380")); x(n) = polcoeff(g,n);
# my(g=OEIS_bfile_gf("A335381")); y(n) = polcoeff(g,n);
# plothraw(vector(3^3,n,n--; x(n)), \
#          vector(3^3,n,n--; y(n)), 1+8+16+32)

#------------------------------------------------------------------------------
# Koch square grid base 5 -> base 3
# A229217   directions
# A332249 \  coords
# A332250 /
#
#
#      2---3            dirs 0 1 0 -1 0
#      |   |            turns L R R L
#  0---1   4---5
#
#            10
#             |
#         8---9            2
#         |                |       A229217 directions
#     2--3,7--6       -1 --O-- 1
#     |   |   |            |
# 0---1   4---5           -2
#
# 1,2,1,-2,1,  2,-1,2,1,2, 1,2,1,-2,1, -2,1,-2,-1,-2, 1,
#
# GP-DEFINE  A229217_turn(n) = {
# GP-DEFINE    my(r);
# GP-DEFINE    while([n,r]=divrem(n,5);r==0, n>0||error()); [1,-1,-1,1][r];
# GP-DEFINE  }
# vector(25,n, A229217_turn(n))
# vector(25,n, A229217_turn(n)==1)
# vector(25,n, A229217_turn(n)==-1)
# not in OEIS: 1,-1,-1,1,1,1,-1,-1,1,-1,1,-1,-1,1,-1,1,-1,-1,1,1,1,-1,-1,1,1
# not in OEIS: 1,0,0,1,1,1,0,0,1,0,1,0,0,1,0,1,0,0,1,1,1,0,0,1,1
# not in OEIS: 0,1,1,0,0,0,1,1,0,1,0,1,1,0,1,0,1,1,0,0,0,1,1,0,0

# GP-DEFINE  \\ A229217 directions 1,2,-1,-2
# GP-DEFINE  my(final=[1,2,-1,-2]); \
# GP-DEFINE  A229217(n) = final[ vecsum([(d==1)-(d==3) | d<-digits(n-1,5)]) %4+1];
# GP-Test  my(v=OEIS_samples("A229217")); /* OFFSET=1 */ \
# GP-Test    v==vector(#v,n, A229217(n))
#
# GP-DEFINE  A229217_final = [1,2,-1,-2];
# GP-DEFINE  dir_to_A229217_final(d) = A229217_final[d%4+1];
# GP-DEFINE  A229217_final_to_dir(f) = [3,2,'none,0,1][f+3];
# GP-Test  A229217_final_to_dir(1) == 0
# GP-Test  A229217_final_to_dir(2) == 1
# GP-Test  A229217_final_to_dir(-1) == 2
# GP-Test  A229217_final_to_dir(-2) == 3
# GP-Test  vector(5^6,n, n++; /* to 1-based */ \
# GP-Test                ((A229217_final_to_dir(A229217(n)) \
# GP-Test                - A229217_final_to_dir(A229217(n-1))) + 1) % 4 - 1) ==\
# GP-Test  vector(5^6,n, A229217_turn(n))

# count 1s and 3s
# vector(25,n, #select(d->d==1,digits(n,5)))
# vector(25,n, #select(d->d==3,digits(n,5)))
# not in OEIS: 1, 0, 0, 0, 1, 2, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1
# not in OEIS: 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 2, 1, 0, 0, 0, 1, 0, 0
# vector(50,n, my(v=digits(n,5)); sum(i=1,#v, (v[i]==1)-(v[i]==3)))
# not in OEIS: 1,0,-1,0,1,2,1,0,1,0,1,0,-1,0,-1,0,-1,-2,-1,0,1,0,-1,0,1,2,1,0,1,2,3,2,1,2,1,2,1,0,1,0,1,0,-1,0,1,2,1,0,1,0
#
# = 1,2,-1,-2 according as d(n) == 0,1,2,3 (mod 4) where d(n) = (base 5 count digit 1's) - (base 5 count digit 3's).

# x=OEIS_bfile_func("A332249");
# y=OEIS_bfile_func("A332250");
# plothraw(vector(5^2,n,n--; x(n)), \
#          vector(5^2,n,n--; y(n)), 1+8+16+32)

# GP-DEFINE  my(table=[[1,0], [I,1], [1,1+I], [-I,2+I], [1,2]]); \
# GP-DEFINE  A332249(n) = {
# GP-DEFINE    my(v=digits(n,5),rot=1);
# GP-DEFINE    for(i=1,#v, [rot,v[i]] = rot*table[v[i]+1]);
# GP-DEFINE    fromdigits(real(v),3);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A332249")); vector(#v,n,n--; A332249(n)) == v


#------------------------------------------------------------------------------
# A065359 PmOneBits net direction, cumulative turn 1 or -2

MyOEIS::compare_values
  (anum => 'A065359',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'TTurn6n');
     my @got;
     my $dir = 0;
     while (@got < $count) {
       push @got, $dir;
       my ($i,$value) = $seq->next;
       $dir += $value;
     }
     return \@got;
   });

# A229216 directions mod 6 as 1,2,3,-1,-2,-3
#
#       3   2          downwards, so outwards of snowflake
#        \ /
#   -1 -- * -- 1       *---*   *---*
#        / \                \ /     \
#      -2   -3               *      ...
#
# Not quite right yet, sample values are for 3 expansions snowflake, not
# infinite "fixed point".
#
# MyOEIS::compare_values
#   (anum => 'A229216',
#    func => sub {
#      my ($count) = @_;
#      my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
#                                                  turn_type => 'TTurn6n');
#      my @got;
#      my $dir = 0;
#      my @dir6_to_A229216 = (1,-3,-2,-1,3,2);
#      while (@got < $count) {
#        push @got, $dir6_to_A229216[$dir%6];
#        my ($i,$value) = $seq->next;
#        $dir += $value;
#      }
#      return \@got;
#    });


#------------------------------------------------------------------------------
#        2
#       / \     /
#  0---1   3---4

# A002450 number of right turns N=1 to N < 4^k
MyOEIS::compare_values
  (anum => 'A002450',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my @got;
     foreach my $k (0 .. $count-1) {
       my $total = 0;
       foreach my $i (1 .. 4**$k-1) {
         $total += $seq->ith($i);
       }
       push @got, $total;
     }
     return \@got;
   });

# A020988 number of left turns N=1 to N < 4^k  = (2/3)*(4^n-1).
# duplicate A084180
MyOEIS::compare_values
  (anum => 'A020988',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Left');
     my @got;
     foreach my $k (0 .. $count-1) {
       my $total = 0;
       foreach my $i (1 .. 4**$k-1) {
         $total += $seq->ith($i);
       }
       push @got, $total;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A050292 TurnsL
#
# Since partial sums of A035263 = Left.
#
MyOEIS::compare_values
  (anum => 'A050292',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Left');
     my @got;
     my $TurnsR = 0;
     while (@got < $count) {
       push @got, $TurnsR;
       my ($i,$value) = $seq->next;
       $TurnsR += $value;
     }
     return \@got;
   });

# A123087 TurnsR
MyOEIS::compare_values
  (anum => 'A123087',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my @got;
     my $TurnsR = 0;
     while (@got < $count) {
       push @got, $TurnsR;
       my ($i,$value) = $seq->next;
       $TurnsR += $value;
     }
     return \@got;
   });

# A068639 TurnsLSR = TurnsL - TurnsR, cumulative +1 or -1 turn my A309873
MyOEIS::compare_values
  (anum => 'A068639',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'LSR');
     my @got;
     my $total = 0;
     while (@got < $count) {
       push @got, $total;
       my ($i,$value) = $seq->next;
       $total += $value;
     }
     return \@got;
   });

# A197911 cumulative left=1,right=2
MyOEIS::compare_values
  (anum => 'A197911',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'SLR'); # 0,1,2
     my @got;
     my $total = 0;
     while (@got < $count) {
       push @got, $total;
       my ($i,$value) = $seq->next;
       $total += $value;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A309873 (mine) turn left=1,right=-1

MyOEIS::compare_values
  (anum => 'A309873',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'LSR');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A016153 - area under the curve, (9^n-4^n)/5

MyOEIS::compare_values
  (anum => 'A016153',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::KochCurve->new;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       my @points;
       my ($n_lo, $n_hi) = $path->level_to_n_range($k);
       foreach my $n ($n_lo .. $n_hi) {
         my ($x,$y) = $path->n_to_xy($n);
         push @points, [$x,$y];
       }
       push @got, points_to_area(\@points);
     }
     return \@got;
   });

sub points_to_area {
  my ($points) = @_;
  if (@$points < 3) {
    return 0;
  }
  require Math::Geometry::Planar;
  my $polygon = Math::Geometry::Planar->new;
  $polygon->points($points);
  return $polygon->area;
}


#------------------------------------------------------------------------------
# A177702 - abs(dX) from N=1 onwards, repeating 1,1,2

MyOEIS::compare_values
  (anum => 'A177702',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathDelta->new (planepath_object => $path,
                                                  delta_type => 'AbsdX');
     $seq->seek_to_i(1);
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A217586
# Not quite turn sequence ...
# differs 0<->1 at n=2^k
#
# a(1) = 1
# if a(n) = 0 then a(2*n) = 1 and a(2*n+1) = 0     # opposite low bit
# if a(n) = 1 then a(2*n) = 0 and a(2*n+1) = 0     # both 0
#
# a(2n+1)=0           # odd always left
# a(2n) = 1-a(n)      # even 0 or 1 as odd or even
# a(4n) = 1-a(2n) = 1-(1-a(n)) = a(n)
# a(4n+2) = 1-a(2n+1) = 1-0 = 1       # 4n+2 always right
# except a(0+2) = 1-a(1) = 1-1 = 0


# A  Right    N    differ
# 1  0         1    *
# 0  1        10    *
# 0  0        11
# 1  0       100    *
# 0  0       101
# 1  1       110
# 0  0       111
# 0  1      1000    *
# 0  0      1001
# 1  1      1010
# 0  0      1011
# 0  0      1100
# 0  0      1101
# 1  1      1110
# 0  0      1111
# 1  0     10000    *
# 0  0
# 1  1
# 0  0
# 0  0
# 0  0
# 1  1
# 0  0
# 1  1

MyOEIS::compare_values
  (anum => q{A217586},
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my @got;
     while (@got < $count) {
       # $seq->next;
       my ($i,$value) = $seq->next;
       if (is_pow2($i)) { $value ^= 1; }
       push @got, $value;
       # push @got, A217586_func($i)
     }
     return \@got;
   });

sub A217586_func {
  my ($n) = @_;
  if ($n < 1) {
    die "A217586_func() must have n>=1";
  }

  {
    while (($n & 3) == 0) {
      $n >>= 2;
    }
    if ($n == 1) {
      return 1;
    }
    if (($n & 3) == 2) {
      if ($n == 2) { return 0; }
      else { return 1; }
    }
    if ($n & 1) {
      return 0;
    }
  }

  # {
  #   if ($n == 1) {
  #     return 1;
  #   }
  #   if (A217586_func($n >> 1)) {
  #     if ($n & 1) {
  #       return 0;
  #     } else {
  #       return 0;
  #     }
  #   } else {
  #     if ($n & 1) {
  #       return 0;
  #     } else {
  #       return 1;
  #     }
  #   }
  # }
  #
  # {
  #   if ($n == 1) {
  #     return 1;
  #   }
  #   my $bit = $n & 1;
  #   if (A217586_func($n >> 1)) {
  #     return 0;
  #   } else {
  #     return $bit ^ 1;
  #   }
  # }
}

sub is_pow2 {
  my ($n) = @_;
  while ($n > 1) {
    if ($n & 1) {
      return 0;
    }
    $n >>= 1;
  }
  return ($n == 1);
}

#------------------------------------------------------------------------------
# A035263 is turn left=1,right=0 at OFFSET=1
# morphism 1 -> 10, 0 -> 11

MyOEIS::compare_values
  (anum => 'A035263',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Left');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

# also left=0,right=1 at even N
MyOEIS::compare_values
  (anum => q{A035263},
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if (($i & 1) == 0) {
         push @got, $value;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A073059 a(4k+3)= 1                      ..11       = 1
#         a(4k+2) = a(4k+4) = 0           ..00 ..10  = 0
#         a(16k+13) = 1                   1101
#         a(4n+1) = a(n)                  ..01       = base4 above
# a(n) = 1-A035263(n-1)  is Koch 1=left,0=right by morphism OFFSET=1
# so A073059 is next turn 0=left,1=right

# ???
#
# MyOEIS::compare_values
#   (anum => q{A073059},
#    func => sub {
#      my ($count) = @_;
#      my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
#                                                  turn_type => 'Left');
#      my @got = (0);
#      while (@got < $count) {
#        $seq->next;
#        my ($i,$value) = $seq->next;
#        push @got, $value;
#      }
#      return \@got;
#    });


#------------------------------------------------------------------------------
# A096268 - morphism turn 1=right,0=left
#   but OFFSET=0 is turn at N=1

MyOEIS::compare_values
  (anum => 'A096268',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A029883 - Thue-Morse first diffs

MyOEIS::compare_values
  (anum => 'A029883',
   fixup => sub {
     my ($bvalues) = @_;
     @$bvalues = map {abs} @$bvalues;
   },
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Left');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A089045 - +/- increment

MyOEIS::compare_values
  (anum => 'A089045',
   fixup => sub {
     my ($bvalues) = @_;
     @$bvalues = map {abs} @$bvalues;
   },
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Left');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003159 - N end in even number of 0 bits, is positions of left turn

MyOEIS::compare_values
  (anum => 'A003159',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Left');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value == 1) {  # left
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A036554 - N end in odd number of 0 bits, position of right turns

MyOEIS::compare_values
  (anum => 'A036554',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value == 1) {  # right
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
