#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2018 Kevin Ryde

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
use List::Util 'sum';
plan tests => 13;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::PyramidRows;


#------------------------------------------------------------------------------
# A079824 sum of digits on step=1 downward diagonals

MyOEIS::compare_values
  (anum => 'A079824',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PyramidRows->new (n_start => 1, step => 1);
     my @got;
     foreach my $y (0 .. $count-1) {
       my $total = 0;
       for (my $i = 0; ; $i++) {
         my $n = $path->xy_to_n($i,$y-$i);
         last if ! defined $n;
         $total += $n;
       }
       push @got, $total;
     }
     return \@got;
   });

# A079823 concatenation of digits on step=1 downward diagonals
MyOEIS::compare_values
  (anum => 'A079823',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PyramidRows->new (n_start => 1, step => 1);
     my @got;
     foreach my $y (0 .. $count-1) {
       my $concat = '';
       for (my $i = 0; ; $i++) {
         my $n = $path->xy_to_n($i,$y-$i);
         last if ! defined $n;
         $concat .= $n;
       }
       push @got, $concat;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A020703 - step=2 permutation N at -X,Y

MyOEIS::compare_values
  (anum => 'A020703',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PyramidRows->new (n_start => 1, step => 2);
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $path->xy_to_n (-$x,$y);
     }
     return \@got;
   });

# A221217 - step=4 permutation N at -X,Y
MyOEIS::compare_values
  (anum => 'A221217',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PyramidRows->new (n_start => 1, step => 4);
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $path->xy_to_n (-$x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A053615 -- distance to pronic is abs(X)

MyOEIS::compare_values
  (anum => 'A053615',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PyramidRows->new (n_start => 0);
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, abs($x);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A103451 -- turn 1=left or right, 0=straight
# but has extra n=1 whereas path first turn at starts N=2

MyOEIS::compare_values
  (anum => 'A103451',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'PyramidRows,step=1',
                                                 turn_type => 'LSR');
     my @got = (1);
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, abs($value);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A103452 -- turn 1=left,0=straight,-1=right
# but has extra n=1 whereas path first turn at starts N=2

MyOEIS::compare_values
  (anum => 'A103452',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'PyramidRows,step=1',
                                                 turn_type => 'LSR');
     my @got = (1);
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A050873 -- step=1 GCD(X+1,Y+1) by rows

MyOEIS::compare_values
  (anum => 'A050873',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::GcdRationals;
     my $path = Math::PlanePath::PyramidRows->new (step => 1);
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       push @got, Math::PlanePath::GcdRationals::_gcd($x+1,$y+1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A051173 -- step=1 LCM(X+1,Y+1) by rows

MyOEIS::compare_values
  (anum => 'A051173',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::GcdRationals;
     my $path = Math::PlanePath::PyramidRows->new (step => 1);
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       push @got, ($x+1) * ($y+1)
         / Math::PlanePath::GcdRationals::_gcd($x+1,$y+1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A215200 -- Kronecker(n-k,k) by rows, n>=1   1<=k<=n

MyOEIS::compare_values
  (anum => q{A215200},
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PyramidRows->new (step => 1);
     require Math::NumSeq::PlanePathCoord;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       next if $x == 0 || $y == 0;
       my $n = $y;
       my $k = $x;
       push @got, Math::NumSeq::PlanePathCoord::_kronecker_symbol($n-$k,$k);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A004201 -- N for which X>=0, step=2

MyOEIS::compare_values
  (anum => 'A004201',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PyramidRows->new (step => 2);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       if ($x >= 0) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A079824 -- diagonal sums
# cf A079825 with rows numbered alternately left and right
# a(21)=(n/6)*(7*n^2-6*n+5)

MyOEIS::compare_values
  (anum => 'A079824',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PyramidRows->new(step=>1);
     for (my $y = 0; @got < $count; $y++) {
       my @diag;
       foreach my $i (0 .. $y) {
         my $n = $path->xy_to_n($i,$y-$i);
         next if ! defined $n;
         push @diag, $n;
       }
       my $total = sum(@diag);
       push @got, $total;

       # if ($y <= 21) {
       #   MyTestHelpers::diag (join('+',@diag)," = $total");
       # }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A000217 -- step=1 X=Y diagonal, the triangular numbers from 1

MyOEIS::compare_values
  (anum => 'A000217',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::PyramidRows->new (step => 1);
     for (my $i = 0; @got < $count; $i++) {
       push @got, $path->xy_to_n($i,$i);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A000290 -- step=2 X=Y diagonal, the squares from 1

MyOEIS::compare_values
  (anum => 'A000290',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::PyramidRows->new (step => 2);
     for (my $i = 0; @got < $count; $i++) {
       push @got, $path->xy_to_n($i,$i);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A167407 -- dDiffXY step=1, extra initial 0

MyOEIS::compare_values
  (anum => 'A167407',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PyramidRows->new (step => 1);
     my @got = (0);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($dx, $dy) = $path->n_to_dxdy ($n);
       push @got, $dx-$dy;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A010052 -- step=2 dY, 1 at squares

MyOEIS::compare_values
  (anum => 'A010052',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::PyramidRows->new (step => 2);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       my ($next_x, $next_y) = $path->n_to_xy ($n+1);
       push @got, $next_y - $y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
