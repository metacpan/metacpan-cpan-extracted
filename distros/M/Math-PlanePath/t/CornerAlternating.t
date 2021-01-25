#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021 Kevin Ryde

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
plan tests => 74;;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
# use Smart::Comments;

require Math::PlanePath::CornerAlternating;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 129;
  ok ($Math::PlanePath::CornerAlternating::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::CornerAlternating->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::CornerAlternating->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::CornerAlternating->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::CornerAlternating->new;
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
  my $path = Math::PlanePath::CornerAlternating->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
  ok ($path->class_x_negative, 0, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 0, 'class_y_negative() instance method');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::CornerAlternating->parameter_info_list;
  ok (join(',',@pnames), 'wider,n_start');
}


#------------------------------------------------------------------------------
# _UNDOCUMENTED__dxdy_list_at_n()

foreach my $wider (0,1,2,3,4, 20,21) {
  foreach my $n_start (0, 1, 37) {
    my $path = Math::PlanePath::CornerAlternating->new (n_start => $n_start);
    my $n;
    for ($n = $path->n_start; ; $n++) {
      my ($dx,$dy) = $path->n_to_dxdy($n);
      last if $dx==0 && $dy==-1;
    }
    ok ($path->_UNDOCUMENTED__dxdy_list_at_n, $n,
        "_UNDOCUMENTED__dxdy_list_at_n() first South");
  }
}


#------------------------------------------------------------------------------
# rect_to_n_range()

{
  my @data = (
              #   4 | 17-18-19-20-21 ...
              #     |  |           |  |
              #   3 | 16-15-14-13 22 29
              #     |           |  |  |
              #   2 |  5--6--7 12 23 28
              #     |  |     |  |  |  |
              #   1 |  4--3  8 11 24 27
              #     |     |  |  |  |  |
              # Y=0 |  1--2  9-10 25-26
              #     +---------------------
              #      X=0  1  2  3  4  5

              [0,0, 2,2,  1,9],   # bottom
              [0,0, 3,2,  1,12],
              [0,0, 4,2,  1,25],  # bottom
              [0,0, 5,2,  1,28],

              [0,0, 2,3,  1,16],
              [0,0, 2,4,  1,19],

              [1,0, 2,3,  2,15],
              [1,0, 2,4,  2,19],

              [1,1, 2,3,  3,15],
              [1,1, 2,4,  3,19],

              #---------
              #  4  |  29-30-31-32-33-34-35-36 ...   wider => 3
              #     |   |                    |  |
              #  3  |  28-27-26-25-24-23-22 37 44
              #     |                     |  |  |
              #  2  |  11-12-13-14-15-16 21 38 43
              #     |   |              |  |  |  |
              #  1  |  10--9--8--7--6 17 20 39 42
              #     |               |  |  |  |  |
              # Y=0 |   1--2--3--4--5 18-19 40-41
              #     |
              #      ----------------------------
              #       X=0  1  2  3  4  5  6  7  8

              [0,0, 5,2,  1,18, wider=>3],  # bottom
              [0,0, 6,2,  1,21, wider=>3],
              [0,0, 7,2,  1,40, wider=>3],  # bottom
              [0,0, 8,2,  1,43, wider=>3],

              [0,0, 5,3,  1,28, wider=>3],
              [0,0, 5,4,  1,34, wider=>3],

              [2,0, 5,3,  3,26, wider=>3],
              [2,0, 5,4,  3,34, wider=>3],

              [2,1, 5,4,  6,34, wider=>3],
              [2,1, 5,3,  6,26, wider=>3],  # min at xy=2,4

             );
  foreach my $elem (@data) {
    my ($x1,$y1, $x2,$y2, $want_lo,$want_hi, @options) = @$elem;
    my $path = Math::PlanePath::CornerAlternating->new (@options);
    my ($n_lo,$n_hi) = $path->rect_to_n_range($x1,$y1, $x2,$y2);
    ok ($n_lo, $want_lo, "n_lo for $x1,$y1, $x2,$y2");
    ok ($n_hi, $want_hi, "n_hi for $x1,$y1, $x2,$y2");
  }
}
exit ;


#------------------------------------------------------------------------------
# first few points

{
  my @data = (

              [ 0, # wider==0
                # [ 1,     0,0,  4 ],
                # [ 1.25,  0,.25   ],
                
                [ 2,  0,1,  6 ],
                [ 3,  1,1,  8 ],
                [ 4,  1,0,  8 ],

                # [ 5,  2,0,  10 ],
                # [ 6,  2,1,  10 ],
                # [ 7,  2,2,  12 ],
                # [ 8,  1,2,  12 ],
                # [ 9,  0,2,  12 ],
                # 
                # [ 10,  0,3, 14 ],
                # [ 11,  1,3, 14 ],
                # [ 12,  2,3, 14 ],
                # [ 13,  3,3, 16 ],
                # [ 14,  3,2, 16 ],
                # [ 15,  3,1, 16 ],
                # [ 16,  3,0, 16 ],
              ],

              # [ 1, # wider==1
              #   [ 1,  0,0 ],
              #   [ 2,  1,0 ],
              # 
              #   [ 3,  1,0 ],
              #   [ 4,  1,1 ],
              #   [ 5,  1,2 ],
              #   [ 6,  0,2 ],
              # 
              #   [  7,  0,2 ],
              #   [  8,  1,2 ],
              #   [  9,  2,2 ],
              #   [ 10,  3,2 ],
              #   [ 11,  3,1 ],
              #   [ 12,  3,0 ],
              # ],
              # 
              # [ 2, # wider==2
              #   [ 1,  0,0,   4 ],
              #   [ 2,  1,0,   6 ],
              #   [ 3,  2,0,   8 ],
              # 
              #   [ 4,  1,0,  10 ],
              #   [ 5,  1,1,  10 ],
              #   [ 6,  1,2,  10 ],
              #   [ 7,  1,3,  12 ],
              #   [ 8,  0,3,  12 ],
              # 
              #   [  9,  0,2, 14 ],
              #   [ 10,  1,2, 14 ],
              #   [ 11,  2,2, 14 ],
              #   [ 12,  3,2, 14 ],
              #   [ 13,  4,2, 16 ],
              #   [ 14,  4,1, 16 ],
              #   [ 15,  4,0, 16 ],
              # ],
              # 
              # [ 10, # wider==10
              #   [ 1,    0,0,   4 ],
              #   [ 10,   9,0,  22 ],
              #   [ 11,  10,0,  24 ],
              #   [ 12,   0,1,  26 ],
              #   [ 13,   1,1,  26 ],
              # ],
             );
  foreach my $we (@data) {
    my ($wider, @wdata) = @$we;
    my $path = Math::PlanePath::CornerAlternating->new (wider => $wider);
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

      # if ($n == int($n)) {
      #   {
      #     my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
      #     ok ($got_nlo <= $n, 1, "rect_to_n_range(0,0,$x,$y) wider=$wider for n=$n, got_nlo=$got_nlo");
      #     ok ($got_nhi >= $n, 1, "rect_to_n_range(0,0,$x,$y) wider=$wider for n=$n, got_nhi=$got_nhi");
      #   }
      #   {
      #     $n = int($n);
      #     my ($got_nlo, $got_nhi) = $path->rect_to_n_range ($x,$y, $x,$y);
      #     ok ($got_nlo, $n, "rect_to_n_range($x,$y,$x,$y) wider=$wider for n=$n, got_nlo=$got_nlo");
      #     ok ($got_nhi, $n, "rect_to_n_range($x,$y,$x,$y) wider=$wider for n=$n, got_nhi=$got_nhi");
      #   }
      # }
      # 
      # if (defined $boundary) {
      #   my $got_boundary = $path->_NOTDOCUMENTED_n_to_figure_boundary($n);
      #   ok ($got_boundary, $boundary, "n=$n xy=$x,$y");
      # }
    }
  }
}
exit;


#------------------------------------------------------------------------------
# random points

{
  for (1 .. 50) {
    my $wider = int(rand(50)); # 0 to 50, inclusive
    my $path = Math::PlanePath::CornerAlternating->new (wider => $wider);

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

#------------------------------------------------------------------------------
exit 0;
