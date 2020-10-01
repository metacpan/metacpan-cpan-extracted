#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2018, 2020 Kevin Ryde

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

use Math::PlanePath::DivisibleColumns;


#------------------------------------------------------------------------------
# A077597 - N on X=Y diagonal, being cumulative count divisors - 1

MyOEIS::compare_values
  (anum => 'A077597',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::DivisibleColumns->new;
     for (my $x = 1; @got < $count; $x++) {
       push @got, $path->xy_to_n($x,$x);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A027751 - Y coord, proper divisors, extra initial 1

MyOEIS::compare_values
  (anum => 'A027751',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::DivisibleColumns->new
       (divisor_type => 'proper');
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A006218 - cumulative count of divisors

MyOEIS::compare_values
  (anum => 'A006218',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::DivisibleColumns->new;
     for (my $x = 1; @got < $count; $x++) {
       push @got, $path->xy_to_n($x,1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
