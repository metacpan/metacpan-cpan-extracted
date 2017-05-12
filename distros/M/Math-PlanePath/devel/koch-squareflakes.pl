#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Math::PlanePath::KochSquareflakes;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # area
  #
  # start diag[0] = 0
  # start straight[0] = 4
  # diag[n+1]     = 2*straight[n] + 2*diag[n]
  # straight[n+1] = 2*straight[n] + 2*diag[n]
  #
  #
  
  require Math::Geometry::Planar;
  my $path = Math::PlanePath::KochSquareflakes->new;
  my @values;
  my $prev_a_log = 0;
  my $prev_len_log = 0;

  foreach my $level (1 .. 7) {
    my $n_level = (4**($level+1) - 1) / 3;
    my $n_end = $n_level + 4**$level;
    my @points;
    foreach my $n ($n_level .. $n_end) {
      my ($x,$y) = $path->n_to_xy($n);
      push @points, [$x,$y];
    }
    ### @points
    my $polygon = Math::Geometry::Planar->new;
    $polygon->points(\@points);
    my $a = $polygon->area;
    my $len = $polygon->perimeter;

    my $a_log = log($a);
    my $len_log = log($len);

    my $d_a_log = $a_log - $prev_a_log;
    my $d_len_log = $len_log - $prev_len_log;
    my $f = $d_a_log / $d_len_log;

    my $formula = area_by_formula($level);

    print "$level  $a $formula\n";
    # print "$level  $d_len_log  $d_a_log   $f\n";
    push @values, $a;

    $prev_a_log = $a_log;
    $prev_len_log = $len_log;
  }
  shift @values;
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;

  sub area_by_formula {
    my ($n) = @_;
    return (9**$n - 4**$n)/5;
    # return (4 * (9**$n - 4**$n)/5 + 16**$n);
  }
}
{
  # max extents of a single side

  # horiz: 1, 4, 14, 48, 164, 560, 1912, 6528, 22288, 76096, 259808, 887040
  # A007070 a(n+1) = 4*a(n) - 2*a(n-1), starting 1,4
  #
  # diag:  1, 3, 10, 34, 116, 396, 1352, 4616, 15760, 53808, 183712, 627232
  # A007052 a(n+1) = 4*a(n) - 2*a(n-1), starting 1,3

  # A007070   max horiz dist from ring start pos     4,14,48,164  side width
  # A206374   N of the max position                  2,9,37,149   corner
  # A003480   X of the max position                  2,7,24,82    last

  # A007052   max vert dist from ring start pos     3,10,34,116    height
  # A072261   N of the max Y position               7,29,117,469   Y axis
  # A007052   Y of the max position                 3,10,34,116

  my $path = Math::PlanePath::KochSquareflakes->new;
  my @values;
  my $coord = 1;
  foreach my $level (1 .. 8) {
    my $nstart = (4**($level+1) - 1) / 3;
    my $nend = $nstart + 4**$level;
    my @start = $path->n_to_xy($nstart);

    my $max_offset = 0;
    my $max_offset_n = $nstart;
    my $max_offset_c = $start[$coord];
    foreach my $n ($nstart .. $nend) {
      my @this = $path->n_to_xy($n);
      my $offset = abs ($this[$coord] - $start[$coord]);
      if ($offset > $max_offset) {
        $max_offset = $offset;
        $max_offset_n = $n;
        $max_offset_c = $this[$coord];
      }
    }
    push @values, $max_offset;

    print "level $level start=$start[$coord] max offset $max_offset at N=$max_offset_n (of $nstart to $nend) Y=$max_offset_c\n";
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}

{
  # X or Y coordinate of first point of ring

  # X or Y coord: 1, 2,7,24,82,280,
  # A003480 1,2,7  OFFSET=0
  # A020727 2,7
  #
  # cf A006012 same recurrence, start 1,2

  my $path = Math::PlanePath::KochSquareflakes->new;
  my @values;
  foreach my $level (1 .. 12) {
    my $nstart = (4**($level+1) - 1) / 3;
    my ($x,$y) = $path->n_to_xy($nstart);
    push @values, -$y;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}

{
  # Xstart power
  # Xstart = b^level
  # b = Xstart^(1/level)
  #
  # D = P^2-4Q = 4^2-4*-2 = 24
  # sqrt(24) = 4.898979485566356196394568149
  #
  my $path = Math::PlanePath::KochSquareflakes->new;
  my $prev = 1;
  foreach my $level (1 .. 12) {
    my $nstart = (4**($level+1) - 1) / 3;
    my ($xstart,$ystart) = $path->n_to_xy($nstart);
    $xstart = -$xstart;
    my $f = $xstart / $prev;
    # my $b = $xstart ** (1/($level+1));
    print "level=$level xstart=$xstart f=$f\n";
    $prev = $xstart;
  }
  print "\n";
  exit 0;
}



{
  my @horiz = (1);
  my @diag  = (1);
  foreach my $i (0 .. 10) {
    $horiz[$i+1] = 2*$horiz[$i] + 2*$diag[$i];
    $diag[$i+1]  = $horiz[$i] + 2*$diag[$i];
    $i++;
  }

  print "horiz: ",join(', ',@horiz),"\n";
  print "diag:  ",join(', ',@diag),"\n";
  exit 0;
}
