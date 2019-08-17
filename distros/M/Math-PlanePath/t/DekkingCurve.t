#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
plan tests => 219;;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::DekkingCurve;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 127;
  ok ($Math::PlanePath::DekkingCurve::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::DekkingCurve->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::DekkingCurve->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::DekkingCurve->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::DekkingCurve->new;
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
  my $path = Math::PlanePath::DekkingCurve->new;
  ok ($path->n_start, 0, 'n_start()');
  ok (! $path->x_negative, 1, 'x_negative()');
  ok (! $path->y_negative, 1, 'y_negative()');
  ok ($path->class_x_negative, 1, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 1, 'class_y_negative() instance method');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::DekkingCurve->parameter_info_list;
  ok (join(',',@pnames), 'arms');
}

{
  my $path = Math::PlanePath::DekkingCurve->new (arms=>2);
  ok (  $path->x_negative, 1, 'arms=2 x_negative()');
  ok (! $path->y_negative, 1, 'arms=2 y_negative()');
  ok ($path->x_negative_at_n, 5, 'arms=2 x_negative_at_n()');
  ok ($path->y_negative_at_n, undef, 'arms=2 x_negative_at_n()');
}
{
  my $path = Math::PlanePath::DekkingCurve->new (arms=>3);
  ok ($path->x_negative, 1, 'arms=3 x_negative()');
  ok ($path->y_negative, 1, 'arms=3 y_negative()');
  ok ($path->x_negative_at_n, 2, 'arms=3 x_negative_at_n()');
  ok ($path->y_negative_at_n, 8, 'arms=3 x_negative_at_n()');
}
{
  my $path = Math::PlanePath::DekkingCurve->new (arms=>4);
  ok ($path->x_negative, 1, 'arms=4 x_negative()');
  ok ($path->y_negative, 1, 'arms=4 y_negative()');
  ok ($path->x_negative_at_n, 2, 'arms=4 x_negative_at_n()');
  ok ($path->y_negative_at_n, 3, 'arms=4 x_negative_at_n()');
}

#------------------------------------------------------------------------------
# level_to_n_range()

{
  # level 0   0 to 1
  # level 1   0 to 25
  # level 2   0 to 625
  my $path = Math::PlanePath::DekkingCurve->new;
  my ($n_lo,$n_hi) = $path->level_to_n_range(2);
  ok ($n_lo,0);
  ok ($n_hi,625);
  ok ($path->n_to_level(25), 1);
  ok ($path->n_to_level(25+1), 2);
  ok ($path->n_to_level(625), 2);
  ok ($path->n_to_level(625+1), 3);
}
{
  my $path = Math::PlanePath::DekkingCurve->new (arms=>3);
  my ($n_lo,$n_hi) = $path->level_to_n_range(2);
  ok ($n_lo,0);
  ok ($n_hi,3*625);
  ok ($path->n_to_level(3*25), 1);
  ok ($path->n_to_level(3*25+1), 2);
  ok ($path->n_to_level(3*625), 2);
  ok ($path->n_to_level(3*625+1), 3);
}

#------------------------------------------------------------------------------
# _UNDOCUMENTED__xseg_is_traversed()

{
  my $path = Math::PlanePath::DekkingCurve->new;
  my $bad = 0;
  foreach my $x (0 .. 5**5) {
    my $want = defined($path->xyxy_to_n_either($x,0, $x+1,0)) ? 1 : 0;
    my $got  = $path->_UNDOCUMENTED__xseg_is_traversed($x) ? 1 : 0;
    if ($got != $want) {
      MyTestHelpers::diag ("_UNDOCUMENTED__xseg_is_traversed($x) got $got want $want");
      last if $bad++ > 10;
    }
  }
  ok ($bad, 0, "_UNDOCUMENTED__xseg_is_traversed");
}
{
  my $path = Math::PlanePath::DekkingCurve->new;
  my $bad = 0;
  foreach my $y (0 .. 5**5) {
    my $want = defined($path->xyxy_to_n_either(0,$y, 0,$y+1)) ? 1 : 0;
    my $got  = $path->_UNDOCUMENTED__yseg_is_traversed($y) ? 1 : 0;
    if ($got != $want) {
      MyTestHelpers::diag ("_UNDOCUMENTED__yseg_is_traversed($y) got $got want $want");
      last if $bad++ > 10;
    }
  }
  ok ($bad, 0, "_UNDOCUMENTED__yseg_is_traversed");
}

#------------------------------------------------------------------------------
# n_to_xy() first few points

{
  my $path = Math::PlanePath::DekkingCurve->new;
  my @data = (
              [ 0,    0,0 ],
              [ 1,    1,0 ],
              [ 2,    2,0 ],
              [ 3,    2,1 ],

              [ 0.25, 0.25,0 ],
              [ 1.25, 1.25,0 ],
              [ 2.25, 2,0.25 ],

              [ 24.25,   5, 0.75 ],
              [ 25.25,   5.25, 0 ],

             );
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

    if ($n == int($n)) {
      {
        my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
        ok ($got_nlo <= $n, 1, "rect_to_n_range(0,0,$x,$y) for n=$n, got_nlo=$got_nlo");
        ok ($got_nhi >= $n, 1, "rect_to_n_range(0,0,$x,$y) for n=$n, got_nhi=$got_nhi");
      }
      {
        $n = int($n);
        my ($got_nlo, $got_nhi) = $path->rect_to_n_range ($x,$y, $x,$y);
        ok ($got_nlo <= $n, 1, "rect_to_n_range($x,$y,$x,$y) for n=$n, got_nlo=$got_nlo");
        ok ($got_nhi >= $n, 1, "rect_to_n_range($x,$y,$x,$y) for n=$n, got_nhi=$got_nhi");
      }
    }
  }
}


#------------------------------------------------------------------------------
# xy_to_n() sample values

{
  my $path = Math::PlanePath::DekkingCurve->new;
  my @data = (
              [ 0,0,  0 ],
              [ 1,0,  1 ],
              [ 2,0,  2 ],
              [ 3,0,  undef ],
              [ 4,0,  undef ],
              [ 5,0,  25 ],
              [ 6,0,  26 ],
              [ 7,0,  27 ],
              [ 8,0,  undef ],
              [ 9,0,  undef ],
              [ 10,0,  50 ],

              [ 0,0,  0 ],
              [ 0,1,  undef ],
              [ 0,2,  undef ],
              [ 0,3,  9 ],
              [ 0,4,  10 ],
              [ 0,5,  undef ],
              [ 0,6,  undef ],
              [ 0,7,  undef ],
              [ 0,8,  114 ],
              [ 0,9,  115 ],
              [ 0,10, undef ],
             );
  foreach my $elem (@data) {
    my ($x, $y, $want_n) = @$elem;
    my $got_n = $path->xy_to_n ($x, $y);
    ok ((! defined $got_n && ! defined $want_n)
        || (defined $got_n && defined $want_n && $want_n == $got_n),
        1,
        "xy_to_n($x,$y)  want=".(defined $want_n ? $want_n : [undef]).
        " got=".(defined $got_n ? $got_n : [undef]));
  }
}

#------------------------------------------------------------------------------
# random fracs

{
  my $path = Math::PlanePath::DekkingCurve->new;
  for (1 .. 20) {
    my $bits = int(rand(20));         # 0 to 20, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive

    my ($x1,$y1) = $path->n_to_xy ($n);
    my ($x2,$y2) = $path->n_to_xy ($n+1);

    foreach my $frac (0.25, 0.5, 0.75) {
      my $want_xf = $x1 + ($x2-$x1)*$frac;
      my $want_yf = $y1 + ($y2-$y1)*$frac;

      # the end of the ring goes towards the start of the current ring, not
      # the next
      if ($y1 == -1 && $x1 >= 0) {
        $want_xf = $x1;
      }

      my $nf = $n + $frac;
      my ($got_xf,$got_yf) = $path->n_to_xy ($nf);

      ok ($got_xf, $want_xf, "n_to_xy($n) frac $frac, x");
      ok ($got_yf, $want_yf, "n_to_xy($n) frac $frac, y");
    }
  }
}

exit 0;
