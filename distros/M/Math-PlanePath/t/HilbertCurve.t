#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
plan tests => 296;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments '###';

require Math::PlanePath::HilbertCurve;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 128;
  ok ($Math::PlanePath::HilbertCurve::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::HilbertCurve->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::HilbertCurve->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::HilbertCurve->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::HilbertCurve->new;
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
  my $path = Math::PlanePath::HilbertCurve->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative() instance method');
  ok ($path->y_negative, 0, 'y_negative() instance method');
}

#------------------------------------------------------------------------------
# first few points

{
  my @data = ([ 0, 0,0 ],
              [ 1, 1,0 ],
              [ 2, 1,1 ],
              [ 3, 0,1 ],

              [ .25,   .25, 0 ],
              [ 1.25,  1, .25 ],
              [ 2.25,  0.75, 1 ],
              [ 3.25,  0, 1.25 ],

              [ 4.25,  0, 2.25 ],
              [ 5.25,  .25, 3 ],
              [ 6.25,  1, 2.75 ],
              [ 7.25,  1.25, 2 ],

              [ 8.25,  2, 2.25 ],
              [ 9.25,  2.25, 3 ],
              [ 10.25,  3, 2.75 ],
              [ 11.25,  3, 1.75 ],

              [ 12.25,  2.75, 1 ],
              [ 13.25,  2, .75 ],
              [ 14.25,  2.25, 0 ],
              [ 15.25,  3.25, 0 ],

              [   19.25,  5.25, 0 ],
              [   37.25,  7, 4.25 ],

              [   31.25,  4, 3.25 ],
              [  127.25,  7.25, 8 ],

              [   63.25,  0, 7.25 ],
              [  255.25,  15.25, 0 ],
              [ 1023.25,  0, 31.25 ],
             );
  my $path = Math::PlanePath::HilbertCurve->new;
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    if ($got_x == 0) { $got_x = 0 }  # avoid "-0"
    if ($got_y == 0) { $got_y = 0 }
    ok ($got_x, $want_x, "n_to_xy() x at n=$n");
    ok ($got_y, $want_y, "n_to_xy() y at n=$n");
  }

  foreach my $elem (@data) {
    my ($want_n, $x, $y) = @$elem;
    next unless $want_n==int($want_n);
    my $got_n = $path->xy_to_n ($x, $y);
    ok ($got_n, $want_n, "n at x=$x,y=$y");
  }

  foreach my $elem (@data) {
    my ($n, $x, $y) = @$elem;
    my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
    next unless $n==int($n);
    ok ($got_nlo <= $n, 1, "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y");
    ok ($got_nhi >= $n, 1, "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y");
  }
}


#------------------------------------------------------------------------------
# rect_to_n_range() random

{
  my $path = Math::PlanePath::HilbertCurve->new;
  for (1 .. 50) {
    my $bits = int(rand(14));         # 0 to 14 inclusive (to fit 32-bit N)
    my $x = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive
    my $y = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive

    my $xcount = int(rand(3));  # 0,1,2
    my $ycount = int(rand(3));  # 0,1,2
    # $xcount = $ycount = 2;

    my $n_min = my $n_max = $path->xy_to_n($x,$y);
    my $n_min_pos = my $n_max_pos = "$x,$y";
    foreach my $xc (0 .. $xcount) {
      foreach my $yc (0 .. $ycount) {
        my $xp = $x+$xc;
        my $yp = $y+$yc;
        ### $xp
        ### $yp
        my $n = $path->xy_to_n($xp,$yp);
        if ($n < $n_min) {
          $n_min = $n;
          $n_min_pos = "$xp,$yp";
        }
        if ($n > $n_max) {
          $n_max = $n;
          $n_max_pos = "$xp,$yp";
        }
      }
    }
    ### $n_min_pos
    ### $n_max_pos

    my ($got_n_min,$got_n_max) = $path->rect_to_n_range ($x+$xcount,$y+$ycount,
                                                         $x,$y);
    ok ($got_n_min == $n_min, 1,
        "rect_to_n_range() on $x,$y rect $xcount,$ycount   n_min_pos=$n_min_pos");
    ok ($got_n_max == $n_max, 1,
        "rect_to_n_range() on $x,$y rect $xcount,$ycount   n_max_pos=$n_max_pos");
  }
}

#------------------------------------------------------------------------------
# random fracs

{
  my $path = Math::PlanePath::HilbertCurve->new;
  for (1 .. 20) {
    my $bits = int(rand(20));         # 0 to 20, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive

    my ($x1,$y1) = $path->n_to_xy ($n);
    my ($x2,$y2) = $path->n_to_xy ($n+1);

    foreach my $frac (0.25, 0.5, 0.75) {
      my $want_xf = $x1 + ($x2-$x1)*$frac;
      my $want_yf = $y1 + ($y2-$y1)*$frac;

      my $nf = $n + $frac;
      my ($got_xf,$got_yf) = $path->n_to_xy ($nf);

      ok ($got_xf, $want_xf, "n_to_xy($n) frac $frac, x");
      ok ($got_yf, $want_yf, "n_to_xy($n) frac $frac, y");
    }
  }
}

exit 0;
