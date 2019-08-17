#!/usr/bin/perl -w

# Copyright 2012, 2013, 2015, 2018, 2019 Kevin Ryde

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
plan tests => 4;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::LTiling;


#------------------------------------------------------------------------------
# A112539 -- X+Y mod 2

MyOEIS::compare_values
  (anum => 'A112539',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::LTiling->new (L_fill => 'left');
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, ($x+$y)%2;
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => q{A112539},
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::LTiling->new (L_fill => 'upper');
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, ($x+$y)%2;
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => q{A112539},
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::LTiling->new (L_fill => 'middle');
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, ($x+$y+1)%2;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A048647 -- N at transpose Y,X

MyOEIS::compare_values
  (anum => 'A048647',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::LTiling->new;
     my @got;
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
