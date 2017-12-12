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
plan tests => 506;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Devel::Comments;

require Math::PlanePath::CellularRule190;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 125;
  ok ($Math::PlanePath::CellularRule190::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::CellularRule190->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::CellularRule190->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::CellularRule190->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::CellularRule190->new;
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
  my $path = Math::PlanePath::CellularRule190->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
  ok ($path->class_x_negative, 1, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 0, 'class_y_negative() instance method');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::CellularRule190->parameter_info_list;
  ok (join(',',@pnames),
      'mirror,n_start');
}
{
  my $path = Math::PlanePath::CellularRule190->new (n_start => 123);
  ok ($path->n_start, 123, 'n_start()');
}

#------------------------------------------------------------------------------
# first few points

{
  my @data = (
              [ 0,
                [ 1, 0,0 ],

                [ 2, -1,1 ],
                [ 3, 0,1 ],
                [ 4, 1,1 ],

                [ 5, -2,2 ],
                [ 6, -1,2 ],
                [ 7, 0,2 ],
                #
                [ 8, 2,2 ],

                [ 15, -4,4 ],
                [ 16, -3,4 ],
                [ 17, -2,4 ],
                #
                [ 18, 0,4 ],
                [ 19, 1,4 ],
                [ 20, 2,4 ],
                #
                [ 21, 4,4 ],

              ],
              
              [ 1,
                [ 1, 0,0 ],

                [ 2, -1,1 ],
                [ 3, 0,1 ],
                [ 4, 1,1 ],

                [ 5, -2,2 ],
                #
                [ 6, 0,2 ],
                [ 7, 1,2 ],
                [ 8, 2,2 ],

                [ 15, -4,4 ],
                #
                [ 16, -2,4 ],
                [ 17, -1,4 ],
                [ 18, 0,4 ],
                #
                [ 19, 2,4 ],
                [ 20, 3,4 ],
                [ 21, 4,4 ],

              ],
             );
  foreach my $elem (@data) {
    my ($mirror, @points) = @$elem;
    my $path = Math::PlanePath::CellularRule190->new (mirror => $mirror);
    foreach my $point (@points) {
      my ($n, $x, $y) = @$point;
      {
        # n_to_xy()
        my ($got_x, $got_y) = $path->n_to_xy ($n);
        if ($got_x == 0) { $got_x = 0 }  # avoid "-0"
        if ($got_y == 0) { $got_y = 0 }
        ok ($got_x, $x, "n_to_xy() mirror=$mirror x at n=$n");
        ok ($got_y, $y, "n_to_xy() mirror=$mirror y at n=$n");
      }
      if ($n==int($n)) {
        # xy_to_n()
        my $got_n = $path->xy_to_n ($x, $y);
        ok ($got_n, $n, "xy_to_n() mirror=$mirror n at x=$x,y=$y");
      }
      {
        $n = int($n);
        my ($got_nlo, $got_nhi) = $path->rect_to_n_range ($x,$y, $x,$y);
        ok ($got_nlo == $n, 1,
            "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y single");
        ok ($got_nhi == $n, 1,
            "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y single");
      }
      {
        $n = int($n);
        my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
        ok ($got_nlo <= $n, 1,
            "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y");
        ok ($got_nhi >= $n, 1,
            "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y");
      }
    }
  }
}

#------------------------------------------------------------------------------
# rect_to_n_range()

{
  my $path = Math::PlanePath::CellularRule190->new;
  foreach my $i (0 .. 50) {
    {
      my $n_left = $path->xy_to_n(-$i,$i);
      my ($n_lo, $n_hi) = $path->rect_to_n_range(0,$i, -$i,$i);
      ok ($n_lo, $n_left);
    }
    {
      my $n_right = $path->xy_to_n($i,$i);
      my ($n_lo, $n_hi) = $path->rect_to_n_range($i,$i, 0,0);
      ok ($n_hi, $n_right);
    }
  }
}


#------------------------------------------------------------------------------
# random points

foreach my $mirror (0, 1) {
  my $path = Math::PlanePath::CellularRule190->new (mirror => $mirror);
  for (1 .. 30) {
    my $bits = int(rand(20));         # 0 to 20, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive

    my ($x,$y) = $path->n_to_xy ($n);
    my $rev_n = $path->xy_to_n ($x,$y);
    if (! defined $rev_n) { $rev_n = 'undef'; }
    ok ($rev_n, $n,
        "xy_to_n($x,$y) mirror=$mirror reverse to expect n=$n, got $rev_n");

    my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
    ok ($n_lo <= $n, 1, "rect_to_n_range() reverse n=$n cf got n_lo=$n_lo");
    ok ($n_hi >= $n, 1, "rect_to_n_range() reverse n=$n cf got n_hi=$n_hi");
  }
}

exit 0;
