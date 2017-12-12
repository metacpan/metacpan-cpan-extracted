#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
plan tests => 75;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::DiamondSpiral;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 125;
  ok ($Math::PlanePath::DiamondSpiral::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::DiamondSpiral->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::DiamondSpiral->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::DiamondSpiral->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::DiamondSpiral->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}


#------------------------------------------------------------------------------
# rect_to_n_range()

{
    my $path = Math::PlanePath::DiamondSpiral->new;
  foreach my $elem
    (
     [0,-2,  -2,-2, 13,39],   # Y=-2, X=-2 to 0 being 39,24,13
     [-2,1,  2,1, 3,21],     # Y=1,  X=-2..2 being 21,10,3,8,17

     [1,-2,  1,2,   2,18], # X=1,  Y=-2..2 being 14,6,2,8,18
     [0,-2,  0,2,   1,13], # X=0,  Y=-2..2 being 13,5,1,3,9
     [-1,-2, -1,2,  4,24], # X=-1, Y=-2..2 being 24,12,4,10,20
     # 
     # [-2,-1, 2,-1,  3,24], # Y=-1, X=-2..2 being 9,3,4,12,24
     # [-2,-1, 1,-1,  3,12], # Y=-1, X=-2..1 being 9,3,4,12

    ) {
    my ($x1,$y1,$x2,$y2, $want_lo, $want_hi) = @$elem;
    my ($got_lo, $got_hi) = $path->rect_to_n_range ($x1,$y1, $x2,$y2);
    ok ($got_lo, $want_lo, "lo on $x1,$y1 $x2,$y2");
    ok ($got_hi, $want_hi, "hi on $x1,$y1 $x2,$y2");
  }
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  my $path = Math::PlanePath::DiamondSpiral->new (height => 123);
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::DiamondSpiral->parameter_info_list;
  ok (join(',',@pnames), 'n_start');
}


#------------------------------------------------------------------------------
# xy_to_n

{
  my @data = ([1, 0,0 ],

              [2, 1,0 ],
              [3, 0,1 ],
              [4, -1,0 ],
              [5, 0,-1 ],
              [5.25, 0.25,-1 ],
              [5.75, 0.75,-1 ],

              [6, 1,-1 ],
              [7, 2,0 ],
              [8, 1,1 ],
              [9, 0,2 ],
              [10, -1,1 ],
              [11, -2,0 ],
              [12, -1,-1 ],
              [13, 0,-2 ],
              [13.25, 0.25,-2 ],
              [13.75, 0.75,-2 ],

              [14, 1,-2 ],
             );
  my $path = Math::PlanePath::DiamondSpiral->new;
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    ok ($got_x, $want_x, "x at n=$n");
    ok ($got_y, $want_y, "y at n=$n");
  }

  foreach my $elem (@data) {
    my ($want_n, $x, $y) = @$elem;
    $want_n = int ($want_n + 0.5);
    my $got_n = $path->xy_to_n ($x, $y);
    ok ($got_n, $want_n, "n at x=$x,y=$y");
  }
}

exit 0;
