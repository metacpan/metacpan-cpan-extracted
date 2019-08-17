#!/usr/bin/perl -w

# Copyright 2012, 2013, 2018, 2019 Kevin Ryde

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
use Math::PlanePath::FilledRings;

use Test;
plan tests => 5;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;


#------------------------------------------------------------------------------
# A036704 -- count |z|<=n+1/2

MyOEIS::compare_values
  (anum => 'A036704',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::FilledRings->new (n_start => 0);
     for (my $x = 1; @got < $count; $x++) {
       push @got, $path->xy_to_n($x,0);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A036708 -- half plane count n-1/2 < |z|<=n+1/2, b>=0
#            first diffs of half plane count
# N(X)/2+X-1 - (N(X-1)/2+X-1-1)
# = (N(X)-N(X-1))/2 + X-1 - X + 2
# = (N(X)-N(X-1))/2 + 1

MyOEIS::compare_values
  (anum => 'A036708',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::FilledRings->new;
     for (my $x = 2; @got < $count; $x++) {
       push @got, ($path->xy_to_n($x,0)-$path->xy_to_n($x-1,0))/2 + 1;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A036707 -- half plane count |z|<=n+1/2, b>=0

MyOEIS::compare_values
  (anum => 'A036707',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::FilledRings->new;
     for (my $x = 1; @got < $count; $x++) {
       push @got, $path->xy_to_n($x,0)/2 + $x-1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A036706 -- 1/4 of first diffs of N along X axis,

MyOEIS::compare_values
  (anum => 'A036706',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::FilledRings->new;
     for (my $x = 1; @got < $count; $x++) {
       push @got, int (($path->xy_to_n($x,0) - $path->xy_to_n($x-1,0)) / 4);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A036705 -- first diffs of N along X axis,
#    count of z=a+bi satisfying n-1/2 < |z| <= n+1/2

MyOEIS::compare_values
  (anum => 'A036705',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::FilledRings->new;
     for (my $x = 1; @got < $count; $x++) {
       push @got, $path->xy_to_n($x,0) - $path->xy_to_n($x-1,0);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
