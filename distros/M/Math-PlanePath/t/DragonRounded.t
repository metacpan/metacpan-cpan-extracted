#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
plan tests => 652;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::DragonRounded;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 129;
  ok ($Math::PlanePath::DragonRounded::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::DragonRounded->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::DragonRounded->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::DragonRounded->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::DragonRounded->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::DragonRounded->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 1); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 3); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 7); }
}
{
  my $path = Math::PlanePath::DragonRounded->new (arms => 4);
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 7); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 15); }
}

#------------------------------------------------------------------------------
# xy_to_n() reversal

foreach my $arms (1 .. 4) {
  my $path = Math::PlanePath::DragonRounded->new (arms => $arms);
  for my $x (0 .. 5) {
    for my $y (0 .. 5) {
      my $n = $path->xy_to_n ($x,$y);
      next if ! defined $n;

      my ($nx,$ny) = $path->n_to_xy ($n);
      ok ($nx, $x, "arms=$arms xy=$x,$y n=$n cf nxy=$nx,$ny");
      ok ($ny, $y, "arms=$arms xy=$x,$y n=$n cf nxy=$nx,$ny");
    }
  }
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  my $path = Math::PlanePath::DragonRounded->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::DragonRounded->parameter_info_list;
  ok (join(',',@pnames), 'arms');
}

#------------------------------------------------------------------------------
# first few points

{
  my @data = (

              [ 2,
                [ 0, 1,0 ],
              ],

              [ 3,
                [ 0, 1,0 ],
              ],

              [ 4,
                [ 0, 1,0 ],
              ],

              [ 1,
                [ 0, 1,0 ],
                [ 1, 2,0 ],
                [ 2, 3,1 ],
                [ 3, 3,2 ],

                [ 4, 2,3 ],
                [ 5, 1,3 ],
                [ 6, 0,4 ],
                [ 7, 0,5 ],

                [ 8, -1,6 ],
                [ 9, -2,6 ],
                [ 10, -3,5 ],
                [ 11, -3,4 ],

                [ 0.25,  1.25, 0 ],
                [ 1.25,  2.25, 0.25 ],
                [ 2.25,  3, 1.25 ],
                [ 3.25,  2.75, 2.25 ],

                [ 4.25,  1.75, 3 ],
                [ 5.25,  0.75, 3.25 ],
                [ 6.25,  0, 4.25 ],
                [ 7.25,  -.25, 5.25 ],

                [ 8.25, -1.25, 6 ],
                [ 9.25, -2.25, 5.75 ],
                [ 10.25, -3, 4.75 ],
                [ 11.25, -3.25, 3.75 ],
              ],
             );
  foreach my $elem (@data) {
    my ($arms, @points) = @$elem;
    my $path = Math::PlanePath::DragonRounded->new (arms => $arms);
    foreach my $point (@points) {
      my ($n, $x, $y) = @$point;
      {
        # n_to_xy()
        my ($got_x, $got_y) = $path->n_to_xy ($n);
        if ($got_x == 0) { $got_x = 0 }  # avoid "-0"
        if ($got_y == 0) { $got_y = 0 }
        ok ($got_x, $x, "n_to_xy() x at n=$n");
        ok ($got_y, $y, "n_to_xy() y at n=$n");
      }
      if ($n==int($n)) {
        # xy_to_n()
        my $got_n = $path->xy_to_n ($x, $y);
        ok ($got_n, $n, "xy_to_n() arms=$arms n at x=$x,y=$y");
      }
      {
        $n = int($n);
        my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
        ok ($got_nlo <= $n, 1, "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y");
        ok ($got_nhi >= $n, 1, "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y");
      }
    }
  }
}


#------------------------------------------------------------------------------
# random fracs

{
  my $path = Math::PlanePath::DragonRounded->new;
  for (1 .. 10) {
    my $bits = int(rand(25));         # 0 to 25, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive

    my ($x1,$y1) = $path->n_to_xy ($n);
    my ($x2,$y2) = $path->n_to_xy ($n+1);

    foreach my $frac (0.25, 0.5, 0.75) {
      my $want_xf = $x1 + ($x2-$x1)*$frac;
      my $want_yf = $y1 + ($y2-$y1)*$frac;

      my $nf = $n + $frac;
      my ($got_xf,$got_yf) = $path->n_to_xy ($nf);

      ok ($got_xf, $want_xf, "n_to_xy($nf) frac $frac, x");
      ok ($got_yf, $want_yf, "n_to_xy($nf) frac $frac, y");
    }
  }
}

#------------------------------------------------------------------------------
# random points

foreach my $arms (1 .. 4) {
  my $path = Math::PlanePath::DragonRounded->new (arms => $arms);
  for (1 .. 30) {
    my $bits = int(rand(25));         # 0 to 25, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive
    ### random point: "n=$n"

    my ($x,$y) = $path->n_to_xy ($n);
    my $rev_n = $path->xy_to_n ($x,$y);
    if (! defined $rev_n) { $rev_n = 'undef'; }
    ok ($rev_n, $n, "xy_to_n($x,$y) reverse to expect n=$n, got $rev_n");

    my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
    ok ($n_lo <= $n, 1, "rect_to_n_range() reverse n=$n cf got n_lo=$n_lo");
    ok ($n_hi >= $n, 1, "rect_to_n_range() reverse n=$n cf got n_hi=$n_hi");
  }
}

exit 0;
