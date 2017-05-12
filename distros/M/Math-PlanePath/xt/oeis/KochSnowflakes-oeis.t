#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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
plan tests => 2;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::KochSnowflakes;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A178789 - num acute angle turns,    4^n + 2
# A002446 - num obtuse angle turns, 2*4^n - 2

MyOEIS::compare_values
  (anum => 'A002446',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $level = 0; @got < $count; $level++) {
       my ($acute, $obtuse) = count_angles_in_level($level);
       push @got, $obtuse;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A178789',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $level = 0; @got < $count; $level++) {
       my ($acute, $obtuse) = count_angles_in_level($level);
       push @got, $acute;
     }
     return \@got;
   });

sub count_angles_in_level {
  my ($level) = @_;
  require Math::NumSeq::PlanePathTurn;
  my $path = Math::PlanePath::KochSnowflakes->new;
  my $n_level = 4**$level;
  my $n_end = 4**($level+1) - 1;
  my @x;
  my @y;
  foreach my $n ($n_level .. $n_end) {
    my ($x,$y) = $path->n_to_xy($n);
    push @x, $x;
    push @y, $y;
  }
  my $acute = 0;
  my $obtuse = 0;
  foreach my $i (0 .. $#x) {
    my $dx = $x[$i-1] - $x[$i-2];
    my $dy = $y[$i-1] - $y[$i-2];
    my $next_dx = $x[$i] - $x[$i-1];
    my $next_dy = $y[$i] - $y[$i-1];
    my $tturn6 = Math::NumSeq::PlanePathTurn::_turn_func_TTurn6($dx,$dy, $next_dx,$next_dy);
    ### $tturn6
    if ($tturn6 == 2 || $tturn6 == 4) {
      $acute++;
    } else {
      $obtuse++;
    }
  }
  return ($acute, $obtuse);
}

#------------------------------------------------------------------------------
exit 0;

