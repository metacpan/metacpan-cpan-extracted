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
plan tests => 4;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::MPeaks;


#------------------------------------------------------------------------------
# A049450 -- N on Y axis, n_start=0, extra initial 0

MyOEIS::compare_values
  (anum => 'A049450',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::MPeaks->new (n_start => 0);
     for (my $y = 0; @got < $count; $y++) {
       push @got, $path->xy_to_n (0,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A056106 -- N on Y axis, n_start=1, extra initial 1

MyOEIS::compare_values
  (anum => 'A056106',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::MPeaks->new;
     for (my $y = 0; @got < $count; $y++) {
       push @got, $path->xy_to_n (0,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A027599 -- N on Y axis, n_start=2, extra initial 6,2

MyOEIS::compare_values
  (anum => 'A027599',
   func => sub {
     my ($count) = @_;
     my @got = (6,2);
     my $path = Math::PlanePath::MPeaks->new (n_start => 2);
     for (my $y = 0; @got < $count; $y++) {
       push @got, $path->xy_to_n (0,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A056109 -- N on X negative axis

MyOEIS::compare_values
  (anum => 'A056109',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::MPeaks->new;
     for (my $x = -1; @got < $count; $x--) {
       push @got, $path->xy_to_n ($x,0);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A045944 -- N on X axis

MyOEIS::compare_values
  (anum => 'A045944',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::MPeaks->new;
     for (my $x = 1; @got < $count; $x++) {
       push @got, $path->xy_to_n ($x,0);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
