#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
plan tests => 160;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::KochSnowflakes;
my $path = Math::PlanePath::KochSnowflakes->new;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::KochSnowflakes::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::KochSnowflakes->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::KochSnowflakes->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::KochSnowflakes->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
  ok ($path->class_x_negative, 1, 'class_x_negative()');
  ok ($path->class_y_negative, 1, 'class_y_negative()');
}

#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::KochSnowflakes->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 1);
    ok ($n_hi, 3); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 4);
    ok ($n_hi, 15); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 16);
    ok ($n_hi, 63); }

  foreach my $level (0 .. 6) {
    my ($n_lo,$n_hi) = $path->level_to_n_range($level);
    my ($x_lo,$y_lo) =  $path->n_to_xy($n_lo);
    my ($x_hi,$y_hi) =  $path->n_to_xy($n_hi);
    my $dx = $x_hi - $x_lo;
    my $dy = $y_hi - $y_lo;
    ok($dx,1);
    ok($dy,1);
  }
}

#------------------------------------------------------------------------------
# rect_to_n_range()

{
  my $path = Math::PlanePath::KochSnowflakes->new;
  foreach my $elem
    (
     [-1,-5, -1,-5,  1,63 ], # N=23 only
     [-2,-5, -1,-5,  1,63 ], # N=23 and point beside it

     [0,0, 0,0,     1,15],   # origin only
     [-9,-3, -9,-3, 1,63],   # N=16 only
     [0,0, -9,-3,   1,63],   # taking in N=16
    ) {
    my ($x1,$y1,$x2,$y2, $want_lo, $want_hi) = @$elem;
    my ($got_lo, $got_hi) = $path->rect_to_n_range ($x1,$y1, $x2,$y2);
    ok ($got_lo, $want_lo, "lo on $x1,$y1 $x2,$y2");
    ok ($got_hi, $want_hi, "hi on $x1,$y1 $x2,$y2");
  }
}

#------------------------------------------------------------------------------
# first few points

{
  my @data = (
              [ 4.5, -2,-1 ],
              [ 5.5, -.5,-1.5 ],

              [ 4, -3,-1 ],
              [ 5, -1,-1 ],
              [ 6, 0,-2 ],

              [ 17, -7,-3 ],
             );
  my $path = Math::PlanePath::KochSnowflakes->new;
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    ok ($got_x, $want_x, "n_to_xy() x at n=$n");
    ok ($got_y, $want_y, "n_to_xy() y at n=$n");
  }

  foreach my $elem (@data) {
    my ($want_n, $x, $y) = @$elem;
    next unless $want_n==int($want_n);
    my $got_n = $path->xy_to_n ($x, $y);
    ok ($got_n, $want_n,
        "xy_to_n($x,$y) N");
  }

  foreach my $elem (@data) {
    my ($n, $x, $y) = @$elem;
    $n = int($n+.5);
    my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
    ok ($got_nlo <= $n, 1, "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y");
    ok ($got_nhi >= $n, 1, "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y");
  }
}

#------------------------------------------------------------------------------
# xy_to_n_list()

{
  my @data = (
              [ -5, -1, [] ],
              [ -5, -2, [] ],

              [ -1, 0, [1] ],
              [ -1, -.333, [1] ],
              [ -1, -.5, [1] ],

              [ -1, -.6, [1,5] ],
              [ -1, -1, [5] ],

              [ 1, 0, [2] ],
              [ 1, -.333, [2] ],
              [ 1, -.5, [2] ],

              [ 1, -.6, [2,7] ],
              [ 1, -1, [7] ],

              [ 0, .666, [3] ],
              [ 0, 1, [3] ],
              [ 0, .5, [3] ],

              [ 0, -1, [] ],
              [ 8, 0, [] ],
              [ 9, 0, [] ],
             );
  foreach my $elem (@data) {
    my ($x,$y, $want_n_aref) = @$elem;
    my $want_n_str = join(',', @$want_n_aref);
    {
      my @got_n_list = $path->xy_to_n_list($x,$y);
      ok (scalar(@got_n_list), scalar(@$want_n_aref),
          "xy_to_n_list($x,$y) count");
      my $got_n_str = join(',', @got_n_list);
      ok ($got_n_str, $want_n_str,
          "xy_to_n_list($x,$y) values");
    }
    {
      my $got_n = $path->xy_to_n($x,$y);
      ok ($got_n, $want_n_aref->[0],
          "xy_to_n($x,$y) first of list");
    }
    {
      my @got_n = $path->xy_to_n($x,$y);
      ok (scalar(@got_n), 1);
      ok ($got_n[0], $want_n_aref->[0]);
    }
  }
}
exit 0;
