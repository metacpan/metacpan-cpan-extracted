#!/usr/bin/perl -w

# Copyright 2013, 2021 Kevin Ryde

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
use Math::BigInt try => 'GMP';   # for bignums in reverse-add steps
use Test;
plan tests => 46;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::PlanePath::WythoffDifference;
use Math::PlanePath::Diagonals;


#------------------------------------------------------------------------------
# A080164 -- Wythoff difference array by anti-diagonals

MyOEIS::compare_values
  (anum => 'A080164',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffDifference->new;
     my $diag = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $d = $diag->n_start; @got < $count; $d++) {
       my ($x,$y) = $diag->n_to_xy($d);  # by anti-diagonals
       push @got, $path->xy_to_n($x,$y);
     }
     return \@got;
   });

# A134571 downwards
MyOEIS::compare_values
  (anum => 'A134571',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffDifference->new;
     my $diag = Math::PlanePath::Diagonals->new (direction => 'down');
     my @got;
     for (my $d = $diag->n_start; @got < $count; $d++) {
       my ($x,$y) = $diag->n_to_xy($d);  # by anti-diagonals
       push @got, $path->xy_to_n($x,$y);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A191361 -- Wythoff difference array X-Y, diagonal containing n

MyOEIS::compare_values
  (anum => 'A191361',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffDifference->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x-$y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A000201 -- Wythoff difference Y axis
#   lower Wythoff sequence, spectrum of phi

MyOEIS::compare_values
  (anum => 'A000201',
   max_count => 200,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffDifference->new;
     my @got;
     for (my $y = Math::BigInt->new(0); @got < $count; $y++) {
       push @got, $path->xy_to_n (0, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A001519 -- Wythoff difference X axis, a(n) = 3*a(n-1) - a(n-2)
# A122367

MyOEIS::compare_values
  (anum => 'A122367',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffDifference->new;
     my @got;
     for (my $x = Math::BigInt->new(0); @got < $count; $x++) {
       push @got, $path->xy_to_n ($x, 0);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A001519',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffDifference->new;
     my @got = (1); # extra initial 1
     for (my $x = Math::BigInt->new(0); @got < $count; $x++) {
       push @got, $path->xy_to_n ($x, 0);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
