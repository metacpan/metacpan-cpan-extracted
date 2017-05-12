#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
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
use List::Util 'min','max';
use Test;
plan tests => 218;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use lib 'xt';
use MyOEIS;

# uncomment this to run the ### lines
# use Smart::Comments;

use Math::PlanePath::ComplexMinus;


#------------------------------------------------------------------------------
# figure boundary

{
  # _UNDOCUMENTED_level_to_figure_boundary()

  foreach my $realpart (1 .. 10) {
    my $path = Math::PlanePath::ComplexMinus->new (realpart => $realpart);
    my $norm = $realpart*$realpart + 1;
    foreach my $level (0 .. 14) {
      my $n_level_end = $norm**$level - 1;
      last if $n_level_end > 10_000;

      my $got = $path->_UNDOCUMENTED_level_to_figure_boundary($level);
      my $want = path_n_to_figure_boundary($path, $n_level_end);
      ok ($got, $want, "_UNDOCUMENTED_level_to_figure_boundary() realpart=$realpart level=$level n_level_end=$n_level_end");
      ### $got
      ### $want
    }
  }
}

# Return the boundary of unit squares at Nstart to N inclusive.
sub path_n_to_figure_boundary {
  my ($path, $n) = @_;
  ### path_n_to_figure_boundary(): $n
  my $boundary = 4;
  foreach my $n ($path->n_start() .. $n-1) {
    ### "n=$n dboundary=".(path_n_to_dboundary($path,$n))
    $boundary += path_n_to_dboundary($path,$n);
  }
  return $boundary;
}

BEGIN {
  my @dir4_to_dx = (1,0,-1,0);
  my @dir4_to_dy = (0,1,0,-1);

  # return the change in figure boundary from N to N+1
  sub path_n_to_dboundary {
    my ($path, $n) = @_;
    $n += 1;
    my ($x,$y) = $path->n_to_xy($n) or do {
      if ($n == $path->n_start - 1) {
        return 4;
      } else {
        return undef;
      }
    };
    ### N+1 at: "n=$n  xy=$x,$y"
    my $dboundary = 4;
    foreach my $i (0 .. $#dir4_to_dx) {
      my $an = $path->xy_to_n($x+$dir4_to_dx[$i], $y+$dir4_to_dy[$i]);
      ### consider: "xy=".($x+$dir4_to_dx[$i]).",".($y+$dir4_to_dy[$i])." is an=".($an||'false')
      $dboundary -= 2*(defined $an && $an < $n);
    }
    ### $dboundary
    return $dboundary;
  }
}

#------------------------------------------------------------------------------
exit 0;
