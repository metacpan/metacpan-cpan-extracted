#!/usr/bin/perl -w

# Copyright 2012, 2013, 2018 Kevin Ryde

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
plan tests => 10;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::ZOrderCurve;
use Math::PlanePath::Diagonals;


#------------------------------------------------------------------------------
# A163328 -- radix=3 diagonals same axis

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

# A163329 -- radix=3 diagonals same axis, inverse
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

#------------------------------------------------------------------------------
# A054238 -- permutation, diagonals same axis

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

# A054239 -- diagonals same axis, inverse
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
# A057300 -- N at transpose Y,X, radix=2

MyOEIS::compare_values
  (anum => 'A057300',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::ZOrderCurve->new;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       ($x, $y) = ($y, $x);
       my $n = $path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163327 -- N at transpose Y,X, radix=3

MyOEIS::compare_values
  (anum => 'A163327',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::ZOrderCurve->new (radix => 3);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       ($x, $y) = ($y, $x);
       my $n = $path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A126006 -- N at transpose Y,X, radix=4

MyOEIS::compare_values
  (anum => 'A126006',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::ZOrderCurve->new (radix => 4);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       ($x, $y) = ($y, $x);
       my $n = $path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A217558 -- N at transpose Y,X, radix=16

MyOEIS::compare_values
  (anum => 'A217558',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::ZOrderCurve->new (radix => 16);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       ($x, $y) = ($y, $x);
       my $n = $path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------

exit 0;
