#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2019 Kevin Ryde

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
plan tests => 8;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

# uncomment this to run the ### lines
#use Smart::Comments '###';

use Math::PlanePath::KnightSpiral;
use Math::PlanePath::SquareSpiral;
my $knight = Math::PlanePath::KnightSpiral->new;
my $square = Math::PlanePath::SquareSpiral->new;


#------------------------------------------------------------------------------
# KnightSpiral
# LSR
# 1,0,1,-1,1,-1,1,-1,0,1,-1,1,1,1,-1,1,1,-1,1,1,-1,1,1,1,-1,1,1,-1,1,1,-1,1,1,1,-1,1,1,-1,1,1,-1,1,1,1,-1,1,1,-1,1,0,1,-1,1,-1

# 18,25,66

# MyOEIS::compare_values
#   (anum => 'A227741',
#    func => sub {
#      my ($count) = @_;
#      $count = 5000;
#      my @got;
#      require Math::NumSeq::PlanePathTurn;
#      my $seq = Math::NumSeq::PlanePathTurn->new(planepath => 'KnightSpiral',
#                                                 turn_type => 'LSR');
#      while (@got < $count) {
#        my ($i, $value) = $seq->next;
#        push @got, $value;
#        if ($value == 0) {
#          print "$i,";
#        }
#      }
#      return \@got;
#    });

# Straight ahead at step to next outer ring is squares.
# South-East continuing around is others.

# vector_modulo(v,i) = v[(i% #v)+1];
# S(k) = 4 * k^2 + vector_modulo([16, 12],k) * k + vector_modulo([18, 9],k)
# vector(10,k,k--; S(k))
# vector(10,k,k--; S(2*k))       \\ A010006
# vector(10,k,k--; S(2*k+1))     \\ A016814
# poldisc(4 * k^2 + 16 * k + 18)
# poldisc(4 * k^2 + 12 * k + 9)
# factor(4 * k^2 + 12 * k + 9)
# 4 * k^2 + 12 * k + 9  == (2*k+3)^2
# factor(4 * k^2 + 16 * k + 18)
# factor(I*(4 * k^2 + 16 * k + 18))
# polroots(4 * k^2 + 16 * k + 18)

#------------------------------------------------------------------------------
# # A306659 - X coordinate
# MyOEIS::compare_values
#   (anum => 'A306659',
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $n = 1; @got < $count; $n++) {
#        my ($x, $y) = $knight->n_to_xy ($n);
#        push @got, $x;
#      }
#      return \@got;
#    });
# 
# # A306660 - Y coordinate
# MyOEIS::compare_values
#   (anum => 'A306660',
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $n = 1; @got < $count; $n++) {
#        my ($x, $y) = $knight->n_to_xy ($n);
#        push @got, $y;
#      }
#      return \@got;
#    });

# Not yet, slightly different innermost ring.
#
# A306659   0, 2, 0, -2, -1, 1, 2, 1, -1, -2, 0, 2, 1, -1, -2, -1, 1, 0, -2, -1,
# A306660   0, 1, 2, 1, -1, -2, 0, 2, 1, -1, -2, -1, 1, 2, 0, -2, -1, 1, 2, 0, -2,
#
#     1 . .
#         2
#
# Line plot of X=A306659, Y=A306660
# http://oeis.org/plot2a?name1=A306659&name2=A306660&tform1=untransformed&tform2=untransformed&shift=0&radiop1=xy&drawpoints=true&drawlines=true

#------------------------------------------------------------------------------
# A068608 - N values in square spiral order, same first step
MyOEIS::compare_values
  (anum => 'A068608',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       push @got, $square->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A068609 - rotate 90 degrees
MyOEIS::compare_values
  (anum => 'A068609',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       ### knight: "$n  $x,$y"
       ($x, $y) = (-$y, $x);
       push @got, $square->xy_to_n ($x, $y);
       ### rotated: "$x,$y"
       ### is: "got[$#got] = $got[-1]"
     }
     return \@got;
   });

# A068610 - rotate 180 degrees
MyOEIS::compare_values
  (anum => 'A068610',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       ($x, $y) = (-$x, -$y);
       push @got, $square->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A068611 - rotate 270 degrees
MyOEIS::compare_values
  (anum => 'A068611',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       ($x, $y) = ($y, -$x);
       push @got, $square->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A068612 - rotate 180 degrees, opp direction, being X negated
MyOEIS::compare_values
  (anum => 'A068612',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       $x = -$x;
       push @got, $square->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A068613 -
MyOEIS::compare_values
  (anum => 'A068613',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       ($x, $y) = (-$y, -$x);
       push @got, $square->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A068614 - clockwise, Y negated
MyOEIS::compare_values
  (anum => 'A068614',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       $y = -$y;
       push @got, $square->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A068615 - transpose
MyOEIS::compare_values
  (anum => 'A068615',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $n (1 .. $count) {
       my ($x, $y) = $knight->n_to_xy ($n);
       ($y, $x) = ($x, $y);
       push @got, $square->xy_to_n ($x, $y);
     }
     return \@got;
   });

exit 0;
