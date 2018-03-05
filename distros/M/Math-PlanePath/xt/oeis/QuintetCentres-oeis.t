#!/usr/bin/perl -w

# Copyright 2013, 2014, 2015, 2018 Kevin Ryde

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
use Math::PlanePath::QuintetCentres;
use Test;
plan tests => 11;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;


#------------------------------------------------------------------------------
# A099456 -- level end Y

MyOEIS::compare_values
  (anum => 'A099456',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::QuintetCentres->new;
     my @got;
     require Math::BigInt;
     for (my $level = Math::BigInt->new(1); @got < $count; $level++) {
       my ($n_lo, $n_hi) = $path->level_to_n_range($level);
       my ($x,$y) = $path->n_to_xy($n_hi);
       push @got, $y;
     }
     return \@got;
   });

# A139011 -- level end X - 1, Re (2+i)^k
MyOEIS::compare_values
  (anum => 'A139011',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::QuintetCentres->new;
     my @got;
     require Math::BigInt;
     for (my $level = Math::BigInt->new(0); @got < $count; $level++) {
       my ($n_lo, $n_hi) = $path->level_to_n_range($level);
       my ($x,$y) = $path->n_to_xy($n_hi);
       push @got, $x + 1;
     }
     return \@got;
   });

# A139011 -- arms=2 level end Y, Re (2+i)^k
MyOEIS::compare_values
  (anum => q{A139011},
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::QuintetCentres->new (arms => 2);
     my @got;
     require Math::BigInt;
     for (my $level = Math::BigInt->new(0); @got < $count; $level++) {
       my ($n_lo, $n_hi) = $path->level_to_n_range($level);
       my ($x,$y) = $path->n_to_xy($n_hi);
       push @got, $y;
     }
     return \@got;
   });



#------------------------------------------------------------------------------

exit 0;
