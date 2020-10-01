#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
plan tests => 336;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::SierpinskiArrowheadCentres;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 128;
  ok ($Math::PlanePath::SierpinskiArrowheadCentres::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::SierpinskiArrowheadCentres->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::SierpinskiArrowheadCentres->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::SierpinskiArrowheadCentres->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::SierpinskiArrowheadCentres->new;
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
  my $path = Math::PlanePath::SierpinskiArrowheadCentres->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
}

#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::SierpinskiArrowheadCentres->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 0); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 2); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 8); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(3);
    ok ($n_lo, 0);
    ok ($n_hi, 26); }
}


#------------------------------------------------------------------------------
# first few points

{
  my @table = ([ [ ], # default triangular
                 [ 0,  0,0 ],
                 [ 1,  1,1 ],
                 [ 2,  -1,1 ],
                 [ 3,  -2,2 ],
                 [ 4,  -3,3 ],
                 [ 5,  -1,3 ],
                 [ 6,  1,3 ],
                 [ 7,  2,2 ],
                 [ 8,  3,3 ],

                 [ .25,   .25, .25 ],
                 [ 1.25,   0.5, 1 ],
                 [ 2.25,   -1.25, 1.25 ],
                 [ 3.25,   -2.25, 2.25 ],
                 [ 4.25,   -2.5, 3 ],
                 [ 5.25,   -.5, 3 ],
                 [ 6.25,   1.25, 2.75 ],
                 [ 7.25,   2.25, 2.25 ],
                 [ 8.25,   3.25, 3.25 ],
               ],

               [ [ align => 'diagonal' ],
                 [ 0,  0,0 ],
                 [ 1,  1,0 ],
                 [ 2,  0,1 ],
                 [ 3,  0,2 ],
                 [ 4,  0,3 ],
                 [ 5,  1,2 ],
                 [ 6,  2,1 ],
                 [ 7,  2,0 ],
                 [ 8,  3,0 ],
               ],

               [ [ align => 'left' ],
                 [ 0,  0,0 ],
                 [ 1,  0,1 ],
                 [ 2,  -1,1 ],
                 [ 3,  -2,2 ],
                 [ 4,  -3,3 ],
                 [ 5,  -2,3 ],
                 [ 6,  -1,3 ],
                 [ 7,  0,2 ],
                 [ 8,  0,3 ],
               ],

               [ [ align => 'right' ],
                 [ 0,  0,0 ],
                 [ 1,  1,1 ],
                 [ 2,  0,1 ],
                 [ 3,  0,2 ],
                 [ 4,  0,3 ],
                 [ 5,  1,3 ],
                 [ 6,  2,3 ],
                 [ 7,  2,2 ],
                 [ 8,  3,3 ],
               ],
              );
  foreach my $t (@table) {
    my ($options, @data) = @$t;
    my $path = Math::PlanePath::SierpinskiArrowheadCentres->new (@$options);

    foreach my $elem (@data) {
      my ($n, $want_x, $want_y) = @$elem;
      my ($got_x, $got_y) = $path->n_to_xy ($n);
      if ($got_x == 0) { $got_x = 0 }  # avoid "-0"
      if ($got_y == 0) { $got_y = 0 }
      ok ($got_x, $want_x, "n_to_xy() x at n=$n  @$options");
      ok ($got_y, $want_y, "n_to_xy() y at n=$n  @$options");
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
      ok ($got_nlo <= $n, 1,
          "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y");
      ok ($got_nhi >= $n, 1,
          "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y");
    }
  }
}

#------------------------------------------------------------------------------
# random fracs

{
  my $path = Math::PlanePath::SierpinskiArrowheadCentres->new;
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
