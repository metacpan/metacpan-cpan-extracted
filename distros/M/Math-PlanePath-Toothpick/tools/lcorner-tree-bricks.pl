#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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

# Usage: perl lcorner-tree-bricks.pl
#
# Print triplets as brick corners.
#
#   +-----------------------+
#   |     |     |     |     |
#   |  +-----+  |  +-----+  |
#   |  |     |  |  |     |  |
#   |--|  +-----+-----+  |--|
#   |  |  |     |     |  |  |
#   |  +--|  +--+--+  |--+  |
#   |     |  |  |  |  |     |
#   |-----+--+--+--+--+-----|
#   |     |  |  |  |  |     |
#   |  +--|  +--+--+  |--+  |
#   |  |  |     |     |  |  |
#   |--|  +-----+-----+  |--|
#   |  |     |  |  |     |  |
#   |  +-----+  |  +-----+  |
#   |     |     |     |     |
#   +-----------------------+


use 5.010;
use strict;
use List::Util 'min', 'max';
use Math::PlanePath::LCornerTree;

my @grid;
my $size = 8;   # or 16 for more
my $wscale = 3;
my $hscale = 2;
my $width = $wscale*$size + 1;
my $height = $hscale*$size + 1;

my $ox = int($width/2);
my $oy = int($height/2);
my $plot = sub {
  my ($x,$y, $char) = @_;
  $x += $ox;
  $y += $oy;
  if ($x >= 0 && $y >= 0) {
    $grid[$x][$y] = $char;
  }
};
my $fetch = sub {
  my ($x,$y, $char) = @_;
  $x += $ox;
  $y += $oy;
  if ($x >= 0 && $y >= 0) {
    return $grid[$x][$y] || ' ';
  } else {
    return ' ';
  }
};

for (my $y = 0; $y < $height; $y += $hscale) {
  for (my $x = 0; $x < $width; $x++) {
    $grid[$x][$y] = ($x % $wscale ? '-' : '+');
  }
}
for (my $x = 0; $x < $width; $x+=$wscale) {
  for (my $y = 0; $y < $height; $y++) {
    $grid[$x][$y] = ($y % $hscale ? '|' : '+');
  }
}

my $path = Math::PlanePath::LCornerTree->new (parts => 4);
my ($n_lo,$n_hi) = $path->rect_to_n_range(0,0,$size,$size);
foreach my $n ($n_lo .. $n_hi) {
  my @n_children = $path->tree_n_children($n) or next;
  my ($prev_x,$prev_y) = $path->n_to_xy(shift @n_children);
  $prev_x += int($size/2);
  $prev_y += int($size/2);
  while (@n_children) {
    my ($x,$y) = $path->n_to_xy(shift @n_children);
    $x += int($size/2);
    $y += int($size/2);
    foreach my $sx (min($x,$prev_x)*$wscale .. max($x,$prev_x)*$wscale) {
      next unless $sx >= 0;
      foreach my $sy (min($y,$prev_y)*$hscale .. max($y,$prev_y)*$hscale) {
        next unless $sy >= 0;
        $grid[$sx+1][$sy+1] = ' ';
        $grid[$sx+2][$sy+1] = ' ';
      }
    }
    $prev_x = $x;
    $prev_y = $y;
  }
}

# foreach my $y (reverse 0 .. $height-1) {
#   foreach my $x (0 .. $width-1) {
#     if ($grid[$x][$y] eq '+'
#         # && (($grid[$x+1][$y] || ' ') ne ' '
#         #     # || ($x > 0 && $grid[$x-1][$y] || ' ') ne ' '
#         #    )
#         && (($grid[$x][$y+1] || ' ') eq ' '
#             || ($y <= 0 || ($grid[$x][$y-1] || ' ') eq ' '))) {
#       $grid[$x][$y] = '-';
#     }
#     if ($grid[$x][$y] eq '+'
# #        && ($grid[$x][$y+1] || ' ') ne ' '
#         && (($grid[$x+1][$y] || ' ') eq ' '
#             || ($x <= 0 || ($grid[$x-1][$y] || ' ') eq ' '))) {
#       $grid[$x][$y] = '|';
#     }
#   }
# }

# mangle the "+" corners between lines
#
foreach my $y (reverse 0 .. $height-1) {
  foreach my $x (0 .. $width-1) {
    if ($x > 0
        && ($grid[$x][$y] || ' ') eq '+'
        && ($grid[$x-1][$y] || ' ') eq '-'
        && ($grid[$x+1][$y] || ' ') eq '-'
        && ($y == 0
            || ($grid[$x][$y-1] || ' ') eq ' '
            || ($grid[$x][$y+1] || ' ') eq ' ')) {
      $grid[$x][$y] = '-';
    }
    if ($y > 0
        && ($grid[$x][$y] || ' ') eq '+'
        && ($grid[$x][$y-1] || ' ') eq '|'
        && ($grid[$x][$y+1] || ' ') eq '|'
        && ($x == 0
            || ($grid[$x-1][$y] || ' ') eq ' '
            || ($grid[$x+1][$y] || ' ') eq ' ')) {
      $grid[$x][$y] = '|';
    }
  }
}


foreach my $y (reverse 0 .. $height-1) {
  foreach my $x (0 .. $width-1) {
    print $grid[$x][$y] || ' ';
  }
  print "\n";
}

exit 0;
