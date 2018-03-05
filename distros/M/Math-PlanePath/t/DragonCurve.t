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
plan tests => 628;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::DragonCurve;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::DragonCurve::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::DragonCurve->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::DragonCurve->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::DragonCurve->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::DragonCurve->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#----------------------------------------------------------------------------
# n_to_dxdy()

{
  my $path = Math::PlanePath::DragonCurve->new;
  { my @dxdy = $path->n_to_dxdy(-1);
    ok (scalar(@dxdy), 0);
  }
  { my @dxdy = $path->n_to_dxdy(0);
    ok (scalar(@dxdy), 2);
    ok ($dxdy[0], 1);
    ok ($dxdy[1], 0);
  }
}

#----------------------------------------------------------------------------
# _UNDOCUMENTED__n_to_turn_LSR()

{
  my $path = Math::PlanePath::DragonCurve->new;
  ok ($path->_UNDOCUMENTED__n_to_turn_LSR(-1), undef);
  ok ($path->_UNDOCUMENTED__n_to_turn_LSR(0), undef);
  ok ($path->_UNDOCUMENTED__n_to_turn_LSR(1), 1);
  ok ($path->_UNDOCUMENTED__n_to_turn_LSR(2), 1);
  ok ($path->_UNDOCUMENTED__n_to_turn_LSR(3), -1);
}

#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::DragonCurve->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 1); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 2); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 4); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(3);
    ok ($n_lo, 0);
    ok ($n_hi, 8); }
}
{
  my $path = Math::PlanePath::DragonCurve->new (arms => 3);
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 3*(2**0 + 1) - 1); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 3*(2**1 + 1) - 1); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 3*(2**2 + 1) - 1); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(3);
    ok ($n_lo, 0);
    ok ($n_hi, 3*(2**3 + 1) - 1); }
}


#------------------------------------------------------------------------------
# turn sequence claimed in the pod

{
  # with Y reckoned increasing upwards
  sub dxdy_to_dir4 {
    my ($dx, $dy) = @_;
    if ($dx > 0) { return 0; }  # east
    if ($dx < 0) { return 2; }  # west
    if ($dy > 0) { return 1; }  # north
    if ($dy < 0) { return 3; }  # south
  }
  sub path_n_dir {
    my ($path, $n) = @_;
    my ($dx,$dy) = $path->n_to_dxdy($n) or die "Oops, no point at ",$n;
    return dxdy_to_dir4 ($dx, $dy);
  }
  # return 0 for left, 1 for right
  sub path_n_turn {
    my ($path, $n) = @_;
    my $prev_dir = path_n_dir ($path, $n-1);
    my $dir = path_n_dir ($path, $n);
    my $turn = ($dir - $prev_dir) % 4;
    if ($turn == 1) { return 0; }
    if ($turn == 3) { return 1; }
    die "Oops, unrecognised turn dir=$dir";
  }

  # return 0 for left, 1 for right
  sub calc_n_turn {
    my ($n) = @_;
    my ($mask,$z);
    $mask = $n & -$n;          # lowest 1 bit, 000100..00
    $z = $n & ($mask << 1);    # the bit above it
    my $turn = ($z == 0 ? 0 : 1);
    # printf "%b   %b  %b  %d\n", $n,$mask, $z, $turn;
    return $turn;


    die if $n == 0;
    while (($n % 2) == 0) {
      $n = int($n/2); # skip low 0s
    }
    $n = int($n/2);   # skip lowest 1
    return ($n % 2);  # next bit is the turn
  }

  # 
  # return 0 for left, 1 for right
  sub calc_n_next_turn {
    my ($n) = @_;
    my ($mask,$w);
    $mask = $n ^ ($n+1);      # low one and below 000111..11
    $w = $n & ($mask + 1);    # the bit above there
    my $turn = ($w == 0 ? 0 : 1);
    return $turn;
  }

  my $path = Math::PlanePath::DragonCurve->new;
  my $bad = 0;
  foreach my $n ($path->n_start + 1 .. 500) {
    {
      my $path_turn = path_n_turn ($path, $n);
      my $calc_turn = calc_n_turn ($n);
      if ($path_turn != $calc_turn) {
        MyTestHelpers::diag ("turn n=$n  path $path_turn calc $calc_turn");
        last if $bad++ > 10;
      }
    }
    {
      my $path_turn = path_n_turn ($path, $n+1);
      my $calc_turn = calc_n_next_turn ($n);
      if ($path_turn != $calc_turn) {
        MyTestHelpers::diag ("next turn n=$n  path $path_turn calc $calc_turn");
        last if $bad++ > 10;
      }
    }
  }
  ok ($bad, 0, "turn sequence");
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  my $path = Math::PlanePath::DragonCurve->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
  ok ($path->class_x_negative, 1, 'class_x_negative()');
  ok ($path->class_y_negative, 1, 'class_y_negative()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::DragonCurve->parameter_info_list;
  ok (join(',',@pnames), 'arms');
}


#------------------------------------------------------------------------------
# xyxy_to_n_list()

foreach my $arms (1 .. 4) {
  my $path = Math::PlanePath::DragonCurve->new (arms => $arms);
  my @got_n_list = $path->xy_to_n_list(0,0);
  my $got_n_list = join(',',@got_n_list);
  my $want_n_list = join(',', 0 .. $arms-1);
  ok ($got_n_list, $want_n_list);
}


#------------------------------------------------------------------------------
# first few points

{
  my @data = (
              [ 0, 0,0 ],
              [ 1, 1,0 ],
              [ 2, 1,1 ],
              [ 3, 0,1 ],
              [ 4, 0,2 ],

              [ 0.25,  0.25, 0 ],
              [ 1.25,  1, 0.25 ],
              [ 2.25,  0.75, 1 ],
              [ 3.25,  0, 1.25 ],

             );
  my $path = Math::PlanePath::DragonCurve->new;
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
# random rect_to_n_range()

foreach my $arms (1 .. 4) {
  my $path = Math::PlanePath::DragonCurve->new (arms => $arms);
  ok ($path->arms_count, $arms, 'arms_count()');

  for (1 .. 5) {
    my $bits = int(rand(25));     # 0 to 25, inclusive
    my $n = int(rand(2**$bits));  # 0 to 2^bits, inclusive

    my ($x,$y) = $path->n_to_xy ($n);

    my $rev_n = $path->xy_to_n ($x,$y);
    ok (defined $rev_n, 1, "xy_to_n($x,$y) arms=$arms reverse n, got undef");

    my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
    ok ($n_lo <= $n, 1,
        "rect_to_n_range() arms=$arms n=$n at xy=$x,$y cf got n_lo=$n_lo");
    ok ($n_hi >= $n, 1,
        "rect_to_n_range() arms=$arms n=$n at xy=$x,$y cf got n_hi=$n_hi");
  }
}


#------------------------------------------------------------------------------
# random n_to_xy() fracs

foreach my $arms (1 .. 4) {
  my $path = Math::PlanePath::DragonCurve->new (arms => $arms);
  for (1 .. 20) {
    my $bits = int(rand(25));         # 0 to 25, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive

    my ($x1,$y1) = $path->n_to_xy ($n);
    my ($x2,$y2) = $path->n_to_xy ($n+$arms);

    foreach my $frac (0.25, 0.5, 0.75) {
      my $want_xf = $x1 + ($x2-$x1)*$frac;
      my $want_yf = $y1 + ($y2-$y1)*$frac;

      my $nf = $n + $frac;
      my ($got_xf,$got_yf) = $path->n_to_xy ($nf);

      ok ($got_xf, $want_xf, "n_to_xy($nf) arms=$arms frac $frac, x");
      ok ($got_yf, $want_yf, "n_to_xy($nf) arms=$arms frac $frac, y");
    }
  }
}

exit 0;
