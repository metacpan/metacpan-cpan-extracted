#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2018, 2021 Kevin Ryde

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
plan tests => 3;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use MyOEIS;
use Math::PlanePath::AnvilSpiral;


#------------------------------------------------------------------------------
# A033581 - N on Y axis (6*n^2) except for initial N=2

MyOEIS::compare_values
  (anum => 'A033581',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::AnvilSpiral->new (wider => 2);
     my @got = (0);
     for (my $y = 1; @got < $count; $y++) {
       push @got, $path->xy_to_n(0,$y);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A136392 - N on Y negative, with offset making n=-Y+1

MyOEIS::compare_values
  (anum => 'A136392',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::AnvilSpiral->new;
     my @got;
     for (my $y = 0; @got < $count; $y--) {
       push @got, $path->xy_to_n(0,$y);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A033569 - N-1 on NW diagonal, wider=1,  (2*n-1)*(3*n+1)

MyOEIS::compare_values
  (anum => 'A033569',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::AnvilSpiral->new (wider => 1);
     my @got = (-1);  # A033569 initial -1 instead of 1
     for (my $i = 1; @got < $count; $i++) {
       push @got, $path->xy_to_n(-$i, $i) - 1;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
