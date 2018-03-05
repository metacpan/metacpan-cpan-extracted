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
plan tests => 360;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::QuintetCurve;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::QuintetCurve::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::QuintetCurve->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::QuintetCurve->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::QuintetCurve->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::QuintetCurve->new;
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
  my $path = Math::PlanePath::QuintetCurve->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
}


#------------------------------------------------------------------------------
# turn sequence

{
  sub dxdy_to_dir4 {
    my ($dx,$dy) = @_;
    if ($dy == 0) {
      if ($dx == 1) { return 0; }
      if ($dx == -1) { return 2; }
    }
    if ($dy == 1) {
      if ($dx == 0) { return 1; }
    }
    if ($dy == -1) {
      if ($dx == 0) { return 3; }
    }
    die "unrecognised $dx,$dy";
  }

  my $path = Math::PlanePath::QuintetCurve->new;
  my $n = $path->n_start;
  my $bad = 0;

  my ($prev_x, $prev_y) = $path->n_to_xy($n++);

  my ($x, $y) = $path->n_to_xy($n++);
  my $dx = $x - $prev_x;
  my $dy = $y - $prev_y;
  my $prev_dir = dxdy_to_dir4($dx,$dy);

  while ($n < 1000) {
    $prev_x = $x;
    $prev_y = $y;

    ($x,$y) = $path->n_to_xy($n);
    $dx = $x - $prev_x;
    $dy = $y - $prev_y;
    my $dir = dxdy_to_dir4($dx,$dy);

    my $want_turn = ($dir - $prev_dir) % 4;
    if ($want_turn == 3) { $want_turn = -1; }
    my $got_turn = $path->_UNDOCUMENTED__n_to_turn_LSR($n-1);

    if ($got_turn != $want_turn) {
      MyTestHelpers::diag ("bad n=$n turn got=$got_turn want=$want_turn");
      MyTestHelpers::diag ("  dir=$dir prev_dir=$prev_dir");
      last if $bad++ > 10;
    }

    $n++;
    $prev_dir = $dir;
  }
  ok ($bad, 0, "turn sequence");
}

#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::QuintetCurve->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 1); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 5); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 25); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(3);
    ok ($n_lo, 0);
    ok ($n_hi, 125); }
}
{
  my $path = Math::PlanePath::QuintetCurve->new (arms => 4);
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 4); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 20); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 100); }
}

#------------------------------------------------------------------------------
# first few points

{
  my @data = (
              # arms=2
              # [ 2,  46,    -2,4 ],
              # [ 2,   1,    -1,1 ],

              # arms=1
              [ 1,   .25,   .25, 0 ],
              [ 1,   .5,    .5, 0 ],
              [ 1,   1.75,  1, -.75 ],

              [ 1,   0,    0,0 ],
              [ 1,   1,    1,0 ],
              [ 1,   2,    1,-1 ],
              [ 1,   3,    2,-1 ],
              [ 1,   4,    2,0 ],

              [ 1,   5,    2,1 ],
              [ 1,   6,    3,1 ],
              [ 1,   7,    4,1 ],

             );
  foreach my $elem (@data) {
    my ($arms, $n, $x, $y) = @$elem;
    my $path = Math::PlanePath::QuintetCurve->new (arms => $arms);
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
        ok ($got_nlo <= $n, 1, "rect_to_n_range(0,0,$x,$y) arms=$arms for n=$n, got_nlo=$got_nlo");
        ok ($got_nhi >= $n, 1, "rect_to_n_range(0,0,$x,$y) arms=$arms for n=$n, got_nhi=$got_nhi");
      }
      {
        $n = int($n);
        my ($got_nlo, $got_nhi) = $path->rect_to_n_range ($x,$y, $x,$y);
        ok ($got_nlo <= $n, 1, "rect_to_n_range($x,$y,$x,$y) arms=$arms for n=$n, got_nlo=$got_nlo");
        ok ($got_nhi >= $n, 1, "rect_to_n_range($x,$y,$x,$y) arms=$arms for n=$n, got_nhi=$got_nhi");
      }
    }
  }
}


#------------------------------------------------------------------------------
# rect_to_n_range()

{
  my $path = Math::PlanePath::QuintetCurve->new;
  my ($n_lo, $n_hi) = $path->rect_to_n_range(0,0, 0,0);
  ok ($n_lo == 0, 1, "rect_to_n_range() 0,0  n_lo=$n_lo");
  ok ($n_hi >= 0, 1, "rect_to_n_range() 0,0  n_hi=$n_hi");
}


#------------------------------------------------------------------------------
# random fracs

{
  my $path = Math::PlanePath::QuintetCurve->new;
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

#------------------------------------------------------------------------------
# random points

{
  my $path = Math::PlanePath::QuintetCurve->new;
  for (1 .. 50) {
    my $bits = int(rand(20));         # 0 to 20, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive

    my ($x,$y) = $path->n_to_xy ($n);
    my $rev_n = $path->xy_to_n ($x,$y);
    if (! defined $rev_n) { $rev_n = 'undef'; }
    ok ($rev_n, $n, "xy_to_n($x,$y) reverse to expect n=$n, got $rev_n");

    my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
    ok ($n_lo, $n, "rect_to_n_range() reverse n=$n cf got n_lo=$n_lo");
    ok ($n_hi, $n, "rect_to_n_range() reverse n=$n cf got n_hi=$n_hi");
  }
}

#------------------------------------------------------------------------------
# reversible

# bit slow ...
{
  my $bad = 0;
  foreach my $arms (1 .. 4) {
    my $path = Math::PlanePath::QuintetCurve->new (arms => $arms);
    for my $n (0 .. 5**4) {
      my ($x,$y) = $path->n_to_xy ($n);
      my $rev_n = $path->xy_to_n ($x,$y);
      if (! defined $rev_n) { $rev_n = 'undef'; }
      if (! defined $rev_n || $rev_n != $n) {
        last if ++$bad > 10;
        MyTestHelpers::diag ("xy_to_n($x,$y) reverse to expect n=$n, got $rev_n");
      }
    }
  }
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
exit 0;
