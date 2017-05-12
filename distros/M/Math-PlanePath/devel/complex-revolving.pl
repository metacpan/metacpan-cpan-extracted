#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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
use List::Util 'min', 'max';

# uncomment this to run the ### lines
use Smart::Comments;

{
  # min/max for level
  $|=1;
  require Math::PlanePath::ComplexRevolving;
  my $path = Math::PlanePath::ComplexRevolving->new;
  my $prev_max = 1;
  my @min = (1);
  for (my $level = 1; $level < 25; $level++) {
    my $n_start = 2**($level-1);
    my $n_end = 2**$level;

    my $min_hypot = 128*$n_end*$n_end;
    my $min_x = 0;
    my $min_y = 0;
    my $min_pos = '';

    my $max_hypot = 0;
    my $max_x = 0;
    my $max_y = 0;
    my $max_pos = '';

    # print "level $level  n=$n_start .. $n_end\n";

    foreach my $n ($n_start .. $n_end) {
      my ($x,$y) = $path->n_to_xy($n);
      my $h = $x*$x + $y*$y;

      if ($h < $min_hypot) {
        $min_hypot = $h;
        $min_pos = "$x,$y";
      }
      if ($h > $max_hypot) {
        $max_hypot = $h;
        $max_pos = "$x,$y";
      }
    }
    # print "$min_hypot,";

    $min[$level] = $min_hypot;

    # print "  min $min_hypot   at $min_x,$min_y\n";
    # print "  max $max_hypot   at $max_x,$max_y\n";
    {
      my $factor = $min_hypot / $min[$level-1];
      my $factor4_level = max($level-4,0);
      my $factor4 = $min_hypot / $min[max($factor4_level)];
      # printf "  min r^2 %5d", $min_hypot;
      printf " 0b%-20b", $min_hypot;
      # print "   at $min_pos";
      # print "  factor $factor";
      # print "  factor[$factor4_level] $factor4";
      # print "  cf formula ", 2**($level-7), "\n";
      print "\n";
    }
    # {
    #   my $factor = $max_hypot / $prev_max;
    #   print "  max r^2 $max_hypot 0b".sprintf('%b',$max_hypot)."   at $max_pos  factor $factor\n";
    # }
    $prev_max = $max_hypot;
  }
  exit 0;
}

{
  require Math::PlanePath::ComplexRevolving;
  require Image::Base::Text;
  my $realpart = 2;
  my $radix = $realpart*$realpart + 1;
  my %seen;
  my $isize = 20;
  my $image = Image::Base::Text->new (-width => 2*$isize+1,
                                      -height => 2*$isize+1);

  foreach my $n (0 .. $radix**6) {
    my $x = 0;
    my $y = 0;
    my $bx = 1;
    my $by = 0;
    foreach my $digit (digits($n,$radix)) {
      if ($digit) {
        $x += $digit * $bx;
        $y += $digit * $by;
        ($bx,$by) = (-$by,$bx);  # (bx+by*i)*i = bx*i - by, rotate +90
      }

      # (bx,by) = (bx + i*by)*(i+$realpart)
      #
      ($bx,$by) = ($realpart*$bx - $by, $bx + $realpart*$by);
    }
    my $dup = ($seen{"$x,$y"}++ ? "  dup" : "");
    printf "%4d  %2d,%2d%s\n", $n, $x,$y, $dup;

    if ($x > -$isize && $x < $isize
        && $y > -$isize && $y < $isize) {
      $image->xy($x+$isize,$y+$isize,'*');
    }
  }
      $image->xy(0+$isize,0+$isize,'+');
  $image->save_fh(\*STDOUT);
  exit 0;

  sub digits {
    my ($n, $radix) = @_;
    my @ret;
    while ($n) {
      push @ret, $n % $radix;
      $n = int($n/$radix);
    }
    return @ret;
  }
}
