#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2018, 2019, 2020, 2021 Kevin Ryde

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
plan tests => 7;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::DiamondSpiral;
my $path = Math::PlanePath::DiamondSpiral->new;

# GP-DEFINE  read("my-oeis.gp");


#------------------------------------------------------------------------------
# A217296 -- permutation DiamondSpiral -> SquareSpiral rotate +90
#   1  2  3  4  5  6   7  8
#   1, 4, 6, 8, 2, 3, 15, 5,

MyOEIS::compare_values
  (anum => 'A217296',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::PlanePath::SquareSpiral;
     my $square = Math::PlanePath::SquareSpiral->new;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       ($x,$y) = (-$y,$x); # rotate +90
       push @got, $square->xy_to_n ($x, $y);
     }
     return \@got;
   });

# inverse
# not in OEIS: 1,3,10,4,12,5,6,2,8,18,9,20,35,21,11,23,39,24,13,14
# MyOEIS::compare_values
#   (anum => 'A217296',
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      require Math::PlanePath::SquareSpiral;
#      my $square = Math::PlanePath::SquareSpiral->new;
#      for (my $n = $path->n_start; @got < $count; $n++) {
#        my ($x, $y) = $square->n_to_xy ($n);
#        ($x,$y) = (-$y,$x); # rotate +90
#        push @got, $path->xy_to_n ($x, $y);
#      }
#      return \@got;
#    });


#------------------------------------------------------------------------------
# A184636 -- N on Y axis, from Y=2 onwards, if this really is 2*n^2

MyOEIS::compare_values
  (anum => 'A184636',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::DiamondSpiral->new (n_start => 0);
     my @got = (3);
     for (my $y = 2; @got < $count; $y++) {
       push @got, $path->xy_to_n(0,$y);
     }
     return \@got;
   });

# A184636 = floor(1/{(n^4+2*n)^(1/4)}), where {}=fractional part
# maybe 2*n^2
# GP-Test  my(v=OEIS_samples("A184636")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, 2*n^2 + if(n==1,1)) == v
# vector(10,n, (n^4+2*n)^(1/4))
# vector(10,n, (n^4+2*n)^(1/4) - n)
# floor((n^4+2*n)^(1/4)) = n
# GP-Test  vector(1000,n, sqrtnint(n^4+2*n, 4)) == \
# GP-Test  vector(1000,n, n)
# GP-Test  (n+1)^4 == n^4  + 4*n^3 + 6*n^2 + 4*n + 1
# factor(4*n^3 + 6*n^2 + 4*n + 1 -2*n)
#
# (n^4+2*n)^(1/4) = floor( (n^4+2*n)^(1/4) ) + frac( (n^4+2*n)^(1/4) )
# (x+1)^(1/4)
# apply(numerator,Vec((x+1)^(1/4)))
# apply(denominator,Vec((x+1)^(1/4)))
# (n^4+2*n)^(1/4) = n + F
# F = (n^4+2*n)^(1/4) - n
# A184636 = floor( 1/F )
# 0 <= 1/F - 2*n^2 < 1  ?
# vector(10,n, (n^4+2*n)^(1/4) - n)
# vector(10,n, 1/( (n^4+2*n)^(1/4) - n ) - 2*n^2 )
# plot(n=1,10, 1/( (n^4+2*n)^(1/4) - n ) - 2*n^2 )
#
# 1/( (n^4+2*n)^(1/4) - n ) - 2*n^2 = y
# 1/( (n^4+2*n)^(1/4) - n ) = y + 2*n^2
# (y + 2*n^2)*( (n^4+2*n)^(1/4) - n ) = 1
# (y + 2*n^2)* (n^4+2*n)^(1/4) = (y + 2*n^2)*n + 1
# (y + 2*n^2)^4 * (n^4+2*n) = ((y + 2*n^2)*n + 1)^4
# (y + 2*n^2)^4 * (n^4+2*n) - ((y + 2*n^2)*n + 1)^4 = 0
# GP-Test  subst( (y + 2*n^2)^4 * (n^4+2*n) - ((y + 2*n^2)*n + 1)^4, y, 0) == \
# GP-Test    -24*n^6 - 8*n^3 - 1
# GP-Test  subst( (y + 2*n^2)^4 * (n^4+2*n) - ((y + 2*n^2)*n + 1)^4, y, 1) == \
# GP-Test    16*n^7 - 24*n^6 + 24*n^5 - 24*n^4 + 4*n^3 - 6*n^2 - 2*n - 1

# 1/( (n^4+2*n)^(1/4) - n ) - 2*n^2 < 0
# 1/( (n^4+2*n)^(1/4) - n ) < 2*n^2
# 2*n^2 * ( (n^4+2*n)^(1/4) - n ) > 1
# 2*n^2*(n^4+2*n)^(1/4) - 2*n^3 > 1
# 2*n^2*(n^4+2*n)^(1/4) > 2*n^3 + 1
# (2*n^2)^4*(n^4+2*n) > (2*n^3 + 1)^4
# (2*n^2)^4*(n^4+2*n) - (2*n^3 + 1)^4  > 0
# -24*n^6 - 8*n^3 - 1 > 0
# 24*n^6 + 8*n^3 + 1 > 0
#
# 1/( (n^4+2*n)^(1/4) - n ) - 2*n^2 > 1
# 1/( (n^4+2*n)^(1/4) - n ) > 2*n^2 + 1
# (2*n^2 + 1) * ( (n^4+2*n)^(1/4) - n ) < 1
# (2*n^2+1)*(n^4+2*n)^(1/4) - (2*n^2+1)*n < 1
# (2*n^2+1)*(n^4+2*n)^(1/4) < (2*n^2+1)*n + 1
# (2*n^2+1)^4*(n^4+2*n) < ((2*n^2+1)*n + 1)^4
# (2*n^2+1)^4*(n^4+2*n) - ((2*n^2+1)*n + 1)^4 < 0
# 16*n^7 - 24*n^6 + 24*n^5 - 24*n^4 + 4*n^3 - 6*n^2 - 2*n - 1 < 0


#------------------------------------------------------------------------------
# A188551 -- N positions of turns Nstart=-1

MyOEIS::compare_values
  (anum => 'A188551',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'DiamondSpiral,n_start=-1',
                                                 turn_type => 'LSR');
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value != 0 && $i >= 1) {
         push @got, $i;
       }
     }
     return \@got;
   });

# also prime
MyOEIS::compare_values
  (anum => 'A188552',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     require Math::Prime::XS;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'DiamondSpiral,n_start=-1',
                                                 turn_type => 'LSR');
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value != 0
           && $i >= 1
           && Math::Prime::XS::is_prime($i)) {
         push @got, $i;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A217015 -- permutation SquareSpiral rotate -90 -> DiamondSpiral
#   1  2  3  4  5  6
#   1, 5, 6, 2, 8, 3, 10, 4,
#
#               19                    3
#             /    \
#           20   9  18                2
#         /    /       \
#       21  10---3---8  17            1
#     /    / |       |\   \
#   22  11   4   1   2   7  16    <- Y=0
#     \    \     |   | /   /
#       23  12   5---6  15  ...      -1
#         \   \        /   /
#           24  13--14  27           -2
#             \        /
#               25--26               -3

#   37--36--35--34--33--32--31              3
#    |                       |
#   38  17--16--15--14--13  30              2
#    |   |               |   |
#   39  18   5---4---3  12  29              1
#    |   |   |       |   |   |
#   40  19   6   1---2  11  28  ...    <- Y=0
#    |   |   |           |   |   |
#   41  20   7---8---9--10  27  52         -1
#    |   |                   |   |
#   42  21--22--23--24--25--26  51         -2
#    |                           |
#   43--44--45--46--47--48--49--50         -3

MyOEIS::compare_values
  (anum => 'A217015',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::PlanePath::SquareSpiral;
     my $square = Math::PlanePath::SquareSpiral->new;
     for (my $n = $square->n_start; @got < $count; $n++) {
       my ($x, $y) = $square->n_to_xy ($n);
       ($x,$y) = ($y,-$x); # rotate -90
       push @got, $path->xy_to_n ($x, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A215468 -- N sum 8 neighbours

MyOEIS::compare_values
  (anum => 'A215468',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       push @got, ($path->xy_to_n($x+1,$y)
                   + $path->xy_to_n($x-1,$y)
                   + $path->xy_to_n($x,$y+1)
                   + $path->xy_to_n($x,$y-1)
                   + $path->xy_to_n($x+1,$y+1)
                   + $path->xy_to_n($x-1,$y-1)
                   + $path->xy_to_n($x-1,$y+1)
                   + $path->xy_to_n($x+1,$y-1));
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A215471 -- primes with >=5 prime neighbours in 8 surround

MyOEIS::compare_values
  (anum => 'A215471',
   func => sub {
     my ($count) = @_;
     require Math::Prime::XS;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       my $num = ((!! Math::Prime::XS::is_prime   ($path->xy_to_n($x+1,$y)))
                  + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y)))
                  + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x,$y+1)))
                  + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x,$y-1)))
                  + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x+1,$y+1)))
                  + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y-1)))
                  + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y+1)))
                  + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x+1,$y-1)))
                 );
       if ($num >= 5) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
