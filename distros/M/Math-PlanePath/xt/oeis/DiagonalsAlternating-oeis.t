#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2015 Kevin Ryde

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
use Math::PlanePath::DiagonalsAlternating;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A056011 -- permutation N at points by Diagonals,direction=up order

MyOEIS::compare_values
  (anum => 'A056011',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::DiagonalsAlternating->new;
     my $diag = Math::PlanePath::Diagonals->new (direction => 'up');
     for (my $n = $diag->n_start; @got < $count; $n++) {
       my ($x, $y) = $diag->n_to_xy ($n);
       push @got, $path->xy_to_n ($x,$y);
     }
     return \@got;
   });

# is self-inverse
MyOEIS::compare_values
  (anum => q{A056011},
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::Diagonals->new (direction => 'up');
     my $diag = Math::PlanePath::DiagonalsAlternating->new;
     for (my $n = $diag->n_start; @got < $count; $n++) {
       my ($x, $y) = $diag->n_to_xy ($n);
       push @got, $path->xy_to_n ($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A056023 -- permutation N at points by Diagonals,direction=up order

MyOEIS::compare_values
  (anum => 'A056023',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::DiagonalsAlternating->new;
     my $diag = Math::PlanePath::Diagonals->new (direction => 'down');
     for (my $n = $diag->n_start; @got < $count; $n++) {
       my ($x, $y) = $diag->n_to_xy ($n);
       push @got, $path->xy_to_n ($x,$y);
     }
     return \@got;
   });

# is self-inverse
MyOEIS::compare_values
  (anum => q{A056023},
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::Diagonals->new (direction => 'down');
     my $diag = Math::PlanePath::DiagonalsAlternating->new;
     for (my $n = $diag->n_start; @got < $count; $n++) {
       my ($x, $y) = $diag->n_to_xy ($n);
       push @got, $path->xy_to_n ($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A038722 -- permutation N at transpose Y,X n_start=1

MyOEIS::compare_values
  (anum => 'A038722',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::DiagonalsAlternating->new;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $path->xy_to_n ($y, $x);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A061579 -- permutation N at transpose Y,X

MyOEIS::compare_values
  (anum => 'A061579',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::DiagonalsAlternating->new (n_start => 0);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $path->xy_to_n ($y, $x);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A131179 -- X axis, extra 0

MyOEIS::compare_values
  (anum => 'A131179',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::DiagonalsAlternating->new;
     for (my $x = 0; @got < $count; $x++) {
       push @got, $path->xy_to_n ($x, 0);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A128918 -- Y axis, extra 0

MyOEIS::compare_values
  (anum => 'A128918',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::DiagonalsAlternating->new;
     for (my $y = 0; @got < $count; $y++) {
       push @got, $path->xy_to_n (0, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
