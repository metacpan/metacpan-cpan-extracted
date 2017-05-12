#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

# uncomment this to run the ### lines
# use Smart::Comments '###';

use Math::PlanePath::DiamondSpiral;
my $path = Math::PlanePath::DiamondSpiral->new;


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

#------------------------------------------------------------------------------
# A217015 -- permutation SquareSpiral rotate -90 -> DiamondSpiral
#   1  2  3  4  5  6
#   1, 5, 6, 2, 8, 3, 10, 4,

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
