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
plan tests => 535;;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
# use Smart::Comments;

require Math::PlanePath::Corner;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::Corner::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::Corner->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::Corner->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::Corner->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::Corner->new;
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
  my $path = Math::PlanePath::Corner->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
  ok ($path->class_x_negative, 0, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 0, 'class_y_negative() instance method');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::Corner->parameter_info_list;
  ok (join(',',@pnames), 'wider,n_start');
}


#------------------------------------------------------------------------------
# first few points

{
  my @data = (

              [ 0, # wider==0
                [ 1,  0,0,  4 ],

                [ 2,  0,1,  6 ],
                [ 3,  1,1,  8 ],
                [ 4,  1,0,  8 ],

                [ 5,  0,2,  10 ],
                [ 6,  1,2,  10 ],
                [ 7,  2,2,  12 ],
                [ 8,  2,1,  12 ],
                [ 9,  2,0,  12 ],

                [ 10,  0,3, 14 ],
                [ 11,  1,3, 14 ],
                [ 12,  2,3, 14 ],
                [ 13,  3,3, 16 ],
                [ 14,  3,2, 16 ],
                [ 15,  3,1, 16 ],
                [ 16,  3,0, 16 ],
              ],

              [ 1, # wider==1
                [ 1,  0,0 ],
                [ 2,  1,0 ],

                [ 3,  0,1 ],
                [ 4,  1,1 ],
                [ 5,  2,1 ],
                [ 6,  2,0 ],

                [  7,  0,2 ],
                [  8,  1,2 ],
                [  9,  2,2 ],
                [ 10,  3,2 ],
                [ 11,  3,1 ],
                [ 12,  3,0 ],
              ],

              [ 2, # wider==2
                [ 1,  0,0,   4 ],
                [ 2,  1,0,   6 ],
                [ 3,  2,0,   8 ],

                [ 4,  0,1,  10 ],
                [ 5,  1,1,  10 ],
                [ 6,  2,1,  10 ],
                [ 7,  3,1,  12 ],
                [ 8,  3,0,  12 ],

                [  9,  0,2, 14 ],
                [ 10,  1,2, 14 ],
                [ 11,  2,2, 14 ],
                [ 12,  3,2, 14 ],
                [ 13,  4,2, 16 ],
                [ 14,  4,1, 16 ],
                [ 15,  4,0, 16 ],
              ],

              [ 10, # wider==10
                [ 1,    0,0,   4 ],
                [ 10,   9,0,  22 ],
                [ 11,  10,0,  24 ],
                [ 12,   0,1,  26 ],
                [ 13,   1,1,  26 ],
              ],
             );
  foreach my $we (@data) {
    my ($wider, @wdata) = @$we;
    my $path = Math::PlanePath::Corner->new (wider => $wider);
    ### $wider
    ### @wdata

    foreach my $elem (@wdata) {
      my ($n, $x,$y, $boundary) = @$elem;
      {
        # n_to_xy()
        my ($got_x, $got_y) = $path->n_to_xy ($n);
        if ($got_x == 0) { $got_x = 0 }  # avoid "-0"
        if ($got_y == 0) { $got_y = 0 }
        ok ($got_x, $x, "n_to_xy() wider=$wider x at n=$n");
        ok ($got_y, $y, "n_to_xy() wider=$wider y at n=$n");
      }
      if ($n==int($n)) {
        # xy_to_n()
        my $got_n = $path->xy_to_n ($x, $y);
        ok ($got_n, $n, "xy_to_n() wider=$wider n at x=$x,y=$y");
      }

      if ($n == int($n)) {
        {
          my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
          ok ($got_nlo <= $n, 1, "rect_to_n_range(0,0,$x,$y) wider=$wider for n=$n, got_nlo=$got_nlo");
          ok ($got_nhi >= $n, 1, "rect_to_n_range(0,0,$x,$y) wider=$wider for n=$n, got_nhi=$got_nhi");
        }
        {
          $n = int($n);
          my ($got_nlo, $got_nhi) = $path->rect_to_n_range ($x,$y, $x,$y);
          ok ($got_nlo, $n, "rect_to_n_range($x,$y,$x,$y) wider=$wider for n=$n, got_nlo=$got_nlo");
          ok ($got_nhi, $n, "rect_to_n_range($x,$y,$x,$y) wider=$wider for n=$n, got_nhi=$got_nhi");
        }
      }

      if (defined $boundary) {
        my $got_boundary = $path->_NOTDOCUMENTED_n_to_figure_boundary($n);
        ok ($got_boundary, $boundary, "n=$n xy=$x,$y");
      }
    }
  }
}


#------------------------------------------------------------------------------
# random points

{
  for (1 .. 50) {
    my $wider = int(rand(50)); # 0 to 50, inclusive
    my $path = Math::PlanePath::Corner->new (wider => $wider);

    my $bits = int(rand(20));         # 0 to 20, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive

    my ($x,$y) = $path->n_to_xy ($n);
    my $rev_n = $path->xy_to_n ($x,$y);
    if (! defined $rev_n) { $rev_n = 'undef'; }
    ok ($rev_n, $n,
        "xy_to_n($x,$y) wider=$wider reverse to expect n=$n, got $rev_n");

    my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
    ok ($n_lo, $n,
        "rect_to_n_range() wider=$wider reverse n=$n cf got n_lo=$n_lo");
    ok ($n_hi, $n,
        "rect_to_n_range() wider=$wider reverse n=$n cf got n_hi=$n_hi");
  }
}

exit 0;
