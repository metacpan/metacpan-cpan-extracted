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
plan tests => 1568;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::DiamondArms;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::DiamondArms::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::DiamondArms->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::DiamondArms->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::DiamondArms->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::DiamondArms->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative, arms_count

{
  my $path = Math::PlanePath::DiamondArms->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
  ok ($path->arms_count, 4, 'arms_count()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::DiamondArms->parameter_info_list;
  ok (join(',',@pnames), '');
}


#------------------------------------------------------------------------------
# first few points

{
  my @data = (
              [ 1, 0,0 ],
              [ 1.25, 0.25,-0.25 ],
              [ 5, 1,-1 ],

              [ 2, 1,0 ],
              [ 2.25, 1.25,0.25 ],
              [ 6, 2,1 ],

              [ 3, 1,1 ],
              [ 3.75, 0.25,1.75 ],
              [ 7, 0,2 ],

              [ 4, 0,1 ],
              [ 4.75, -.75,0.25 ],
              [ 8, -1,0 ],

             );
  my $path = Math::PlanePath::DiamondArms->new;
  foreach my $elem (@data) {
    my ($n, $x, $y) = @$elem;
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
      ok ($got_n, $n, "xy_to_n() n at x=$x,y=$y");
    }
    {
      $n = int($n);
      my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
      ok ($got_nlo <= $n, 1, "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y");
      ok ($got_nhi >= $n, 1, "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y");
    }
  }
}

#------------------------------------------------------------------------------
# xy_to_n() reverse n_to_xy() and rect_to_n_range()

{
  my $path = Math::PlanePath::DiamondArms->new;
  for (1 .. 500) {
    my $bits = int(rand(25));         # 0 to 25, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive
    my ($x,$y) = $path->n_to_xy ($n);

    {
      my $rev_n = $path->xy_to_n ($x,$y);
      ok ($rev_n, $n, "xy_to_n() reverse n=$n");
    }
    {
      my ($n_lo,$n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
      ok ($n_lo <= $n, 1, "rect_to_n_range() on $x,$y = $n n_lo $n_lo");
      ok ($n_hi >= $n, 1, "rect_to_n_range() on $x,$y = $n n_hi $n_hi");
    }
  }
}


exit 0;
