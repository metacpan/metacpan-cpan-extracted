#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

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
use warnings;

# uncomment this to run the ### lines
#use Smart::Comments;


{
  # depth_to_n()

  require Math::PlanePath::UlamWarburton;
  my $path = Math::PlanePath::UlamWarburton->new(parts=>'octant');
  for (my $depth = 0; $depth < 35; $depth++) {
    my $n = $path->tree_depth_to_n($depth);
    my ($x,$y) = $path->n_to_xy($n);
    my $rn = $path->xy_to_n($x,$y);
    my $diff = $rn - $n;
    print "$depth $n  $x,$y     $diff\n";
  }
  exit 0;
}

{
  # n_to_depth()                    1       6                16
  #                                 2       7,8              17,18
  #            14                   3       9,10             19,20
  #         15 10 13       20       4,5     11,12,13,14,15
  #       5     8    12    18 
  # 1  2  3  4  6  7  9 11 16 17 19
  # --------------------------
  # 0  1  2  3  4  5  6  7  8

  require Math::PlanePath::UlamWarburton;
  my $path = Math::PlanePath::UlamWarburton->new(parts=>'octant');
  for (my $n = 1; $n <= 35; $n++) {
    my $depth = $path->tree_n_to_depth($n);
    print "$n $depth\n";
  }
  exit 0;
}

{
  # height
  # my $class = 'Math::PlanePath::UlamWarburton';
  # my $class = 'Math::PlanePath::UlamWarburtonQuarter';
  # my $class = 'Math::PlanePath::ToothpickUpist';
   my $class = 'Math::PlanePath::LCornerTree';
  eval "require $class";
  require Math::BaseCnv;
  my $path = $class->new (parts => 1);
  my $prev_depth = 0;
  for (my $n = $path->n_start;; $n++) {
    my $depth = $path->tree_n_to_depth($n);
    my $n_depth = $path->tree_depth_to_n($depth);
    if ($depth != $prev_depth) {
      print "\n";
      last if $depth > 65;
      $prev_depth = $depth;
    }
    my $calc_height = $path->tree_n_to_subheight($n);
    my $search_height = path_tree_n_to_subheight_by_search($path,$n);
    my $n3 = Math::BaseCnv::cnv($n - $n_depth, 10,3);
    $search_height //= 'undef';
    $calc_height //= 'undef';
    my $diff = ($search_height eq $calc_height ? '' : '  ***');
    printf "%2d %2d %3s  %5s %5s%s\n",
      $depth, $n, $n3, $search_height, $calc_height, $diff;
  }
  exit 0;

  sub path_tree_n_to_subheight_by_search {
    my ($self, $n) = @_;
    my @n = ($n);
    my $height = 0;
    for (;;) {
      @n = map {$self->tree_n_children($_)} @n
        or return $height;
      $height++;
      if (@n > 400 || $height > 70) {
        return undef;  # presumed infinite
      }
    }
  }
}

{
  # number of children
  require Math::PlanePath::UlamWarburton;
  require Math::PlanePath::UlamWarburtonQuarter;
  # my $path = Math::PlanePath::UlamWarburton->new;
  my $path = Math::PlanePath::UlamWarburtonQuarter->new;
  my $prev_depth = 0;
  for (my $n = $path->n_start; ; $n++) {
    my $depth = $path->tree_n_to_depth($n);
    if ($depth != $prev_depth) {
      $prev_depth = $depth;
      print "\n";
      last if $depth > 40;
    }
    my $num_children = $path->tree_n_num_children($n);
    print "$num_children,";
  }
  print "\n";
  exit 0;
}
# turn on u(0) = 1
#         u(1) = 1
#         u(n) = 4 * 3^ones(n-1) - 1
# where ones(x) = number of 1 bits   A000120
#
{
  my @yx;
  sub count_around {
    my ($x,$y) = @_;
    return ((!! $yx[$y+1][$x])
            + (!! $yx[$y][$x+1])
            + ($x > 0 && (!! $yx[$y][$x-1]))
            + ($y > 0 && (!! $yx[$y-1][$x])));
  }
  my (@turn_x,@turn_y);
  sub turn_on {
    my ($x,$y) = @_;
    ### turn_on(): "$x,$y"
    if (! $yx[$y][$x] && count_around($x,$y) == 1) {
      push @turn_x, $x;
      push @turn_y, $y;
    }
  }

  my $print_grid = 1;
  my $cumulative = 1;


  my @lchar = ('a' .. 'z');
  $yx[0][0] = $lchar[0];
  for my $level (1 .. 20) {
    print "\n";

    printf "level %d  %b\n", $level, $level;
    if ($print_grid) {
      foreach my $row (reverse @yx) {
        foreach my $cell (@$row) {
          print ' ', (defined $cell #&& ($cell eq 'p' || $cell eq 'o')
                      ? $cell : ' ');
        }
        print "\n";
      }
      print "\n";
    }

    {
      my $count = 0;
      foreach my $row (reverse @yx) {
        foreach my $cell (@$row) {
          $count += defined $cell;
        }
      }
      print "total $count\n";
    }


    foreach my $y (0 .. $#yx) {
      my $row = $yx[$y];
      foreach my $x (0 .. $#$row) {
        $yx[$y][$x] or next;
        ### cell: $yx[$y][$x]

        turn_on ($x, $y+1);
        turn_on ($x+1, $y);
        if ($x > 0) {
          turn_on ($x-1, $y);
        }
        if ($y > 0) {
          turn_on ($x, $y-1);
        }
      }
    }
    print "extra ",scalar(@turn_x),"\n";

    my %seen_turn;
    for (my $i = 0; $i < @turn_x; ) {
      my $key = "$turn_x[$i],$turn_y[$i]";
      if ($seen_turn{$key}) {
        splice @turn_x,$i,1;
        splice @turn_y,$i,1;
      } else {
        $seen_turn{$key} = 1;
        $i++;
      }
    }

    my $e = 4*(scalar(@turn_x)-2)+4;
    $cumulative += $e;
    print "extra $e  cumulative $cumulative\n";
    ### @turn_x
    ### @turn_y
    while (@turn_x) {
      $yx[pop @turn_y][pop @turn_x] = ($lchar[$level]||'z');
    }
    ### @yx
  }
  exit 0;
}
