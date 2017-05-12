#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use Math::PlanePath::LCornerReplicate;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # last point in each level

  my $path = Math::PlanePath::LCornerReplicate->new;
  foreach my $level (0 .. 20) {
    my ($n_lo,$n_hi) = $path->level_to_n_range($level);
    my ($x,$y) = $path->n_to_xy($n_hi);
    $x = sprintf '%0*b', $level, $x;
    $y = sprintf '%0*b', $level, $y;
    printf "%15d %-20s %-20s\n", $n_hi, $x, $y;
  }
  print "\n";

  foreach my $coord (0, 1) {
    {
      my @values;
      foreach my $level (0 .. 11) {
        my ($n_lo,$n_hi) = $path->level_to_n_range($level);
        my @coords = $path->n_to_xy($n_hi);
        my $c = $coords[$coord];
        print "$c, ";
        if ($c) {
          push @values, $c;
        }
      }
      print "\n";
      require Math::OEIS::Grep;
      Math::OEIS::Grep->search(array => \@values, verbose => 1);
    }
    {
      my @values;
      foreach my $level (0 .. 8) {
        my ($n_lo,$n_hi) = $path->level_to_n_range($level);
        my ($x,$y) = $path->n_to_xy($n_hi);
        my @coords = $path->n_to_xy($n_hi);
        my $c = $coords[$coord];
        $c = sprintf '%0*b', $level, $c;
        print "$c, ";
        $c =~ s/^0+//;
        if ($c) {
          push @values, $c;
        }
      }
      print "\n";
      require Math::OEIS::Grep;
      Math::OEIS::Grep->search(array => \@values, verbose => 1);
    }
    print "\n";
  }

  exit 0;
}
