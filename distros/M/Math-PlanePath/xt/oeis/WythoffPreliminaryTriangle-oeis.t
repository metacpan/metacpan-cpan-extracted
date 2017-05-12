#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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
use List::Util 'max';
use Test;
plan tests => 46;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::PlanePath::WythoffPreliminaryTriangle;


#------------------------------------------------------------------------------
# A165359 column 1 of left justified Wythoff, gives preliminary triangle Y

MyOEIS::compare_values
  (anum => 'A165359',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffPreliminaryTriangle->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A165360 column 2 of left justified Wythoff, gives preliminary triangle X

MyOEIS::compare_values
  (anum => 'A165360',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffPreliminaryTriangle->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A166309 Preliminary Wythoff Triangle, N by rows

MyOEIS::compare_values
  (anum => 'A166309',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::PyramidRows;
     my $path = Math::PlanePath::WythoffPreliminaryTriangle->new;
     my $rows = Math::PlanePath::PyramidRows->new (step=>1);
     my @got;
     for (my $r = $rows->n_start; @got < $count; $r++) {
       my ($x,$y) = $rows->n_to_xy($r);  # by rows
       $y += 1;
       push @got, $path->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
