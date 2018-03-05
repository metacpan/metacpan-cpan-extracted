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
plan tests => 146;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::KochCurve;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::KochCurve::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::KochCurve->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::KochCurve->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::KochCurve->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::KochCurve->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# random n_to_dxdy()

{
  my $path = Math::PlanePath::KochCurve->new;
  foreach (1 .. 20) {
    my $bits = int(rand(25));     # 0 to 25, inclusive
    my $n = int(rand(2**$bits));  # 0 to 2^bits, inclusive
    $n += random_quarter();

    my ($x,$y) = $path->n_to_xy ($n);
    my ($next_x,$next_y) = $path->n_to_xy ($n+1);
    my $delta_dx = $next_x - $x;
    my $delta_dy = $next_y - $y;

    my ($func_dx,$func_dy) = $path->n_to_dxdy ($n);
    ok ($func_dx, $delta_dx, "n_to_dxdy($n) dx at xy=$x,$y");
    ok ($func_dy, $delta_dy, "n_to_dxdy($n) dy at xy=$x,$y");
  }
}

# return 0, 0.25, 0.5 or 0.75
sub random_quarter {
  int(rand(4)) / 4;
}

#------------------------------------------------------------------------------
# random rect_to_n_range()

{
  require Math::PlanePath::KochCurve;
  my $path = Math::PlanePath::KochCurve->new;
  for (1 .. 5) {
    my $bits = int(rand(25));     # 0 to 25, inclusive
    my $n = int(rand(2**$bits));  # 0 to 2^bits, inclusive

    my ($x,$y) = $path->n_to_xy ($n);

    my $rev_n = $path->xy_to_n ($x,$y);
    ok (defined $rev_n, 1,
        "xy_to_n($x,$y) reverse n, got undef");

    my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
    ok ($n_lo <= $n, 1,
        "rect_to_n_range() n=$n at xy=$x,$y cf got n_lo=$n_lo");
    ok ($n_hi >= $n, 1,
        "rect_to_n_range() n=$n at xy=$x,$y cf got n_hi=$n_hi");
  }
}

#------------------------------------------------------------------------------
# rect_to_n_range()

{
  my $path = Math::PlanePath::KochCurve->new;
  foreach my $elem
    (
     [4,1, 7,1, 5,5],   # Y=1 X=4..7 being N=5 only

     [0,0, 9,3,   0,8],
     [9,3, 9,3,   8,8],
     [10,2, 10,2, 9,9],
     [11,1, 11,1, 11,11],
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
  my $path = Math::PlanePath::KochCurve->new;
  ok ($path->n_start, 0, 'n_start()');
  ok (! $path->x_negative, 1, 'x_negative()');
  ok (! $path->y_negative, 1, 'y_negative()');
  ok (! $path->class_x_negative, 1, 'class_x_negative()');
  ok (! $path->class_y_negative, 1, 'class_y_negative()');
}

#------------------------------------------------------------------------------
# first few points

{
  my @data = ([ 0.5, 1,0 ],
              [ 3.5, 5,0 ],


              [ 0, 0,0 ],
              [ 1, 2,0 ],
              [ 2, 3,1 ],
              [ 3, 4,0 ],

              [ 4, 6,0 ],
              [ 5, 7,1 ],
              [ 6, 6,2 ],
              [ 7, 8,2 ],

              [ 8, 9,3 ],
             );
  my $path = Math::PlanePath::KochCurve->new;
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    ok ($got_x, $want_x, "x at n=$n");
    ok ($got_y, $want_y, "y at n=$n");
  }

  foreach my $elem (@data) {
    my ($want_n, $x, $y) = @$elem;
    next unless $want_n==int($want_n);
    my $got_n = $path->xy_to_n ($x, $y);
    ok ($got_n, $want_n, "n at x=$x,y=$y");
  }

  foreach my $elem (@data) {
    my ($n, $x, $y) = @$elem;
    if ($n == int($n)) {
      my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
      ok ($got_nlo == 0, 1, "rect_to_n_range() got_nlo=$got_nlo at n=$n,x=$x,y=$y");
      ok ($got_nhi == $n, 1, "rect_to_n_range() got_nhi=$got_nhi at n=$n,x=$x,y=$y");

      ($got_nlo, $got_nhi) = $path->rect_to_n_range ($x,$y, $x,$y);
      ok ($got_nlo == $n, 1, "rect_to_n_range() got_nlo=$got_nlo at n=$n,x=$x,y=$y");
      ok ($got_nhi == $n, 1, "rect_to_n_range() got_nhi=$got_nhi at n=$n,x=$x,y=$y");
    }
  }
}


#------------------------------------------------------------------------------
# xy_to_n() distinct n

{
  my $path = Math::PlanePath::KochCurve->new;
  my $bad = 0;
  my %seen;
  my $xlo = -5;
  my $xhi = 100;
  my $ylo = -5;
  my $yhi = 100;
  my ($nlo, $nhi) = $path->rect_to_n_range($xlo,$ylo, $xhi,$yhi);
  my $count = 0;
 OUTER: for (my $x = $xlo; $x <= $xhi; $x++) {
    for (my $y = $ylo; $y <= $yhi; $y++) {
      next if ($x ^ $y) & 1;
      my $n = $path->xy_to_n ($x,$y);
      next if ! defined $n;  # sparse

      if ($seen{$n}) {
        MyTestHelpers::diag ("x=$x,y=$y n=$n seen before at $seen{$n}");
        last if $bad++ > 10;
      }
      if ($n < $nlo) {
        MyTestHelpers::diag ("x=$x,y=$y n=$n below nlo=$nlo");
        last OUTER if $bad++ > 10;
      }
      if ($n > $nhi) {
        MyTestHelpers::diag ("x=$x,y=$y n=$n above nhi=$nhi");
        last OUTER if $bad++ > 10;
      }
      $seen{$n} = "$x,$y";
      $count++;
    }
  }
  ok ($bad, 0, "xy_to_n() coverage and distinct, $count points");
}


#------------------------------------------------------------------------------
# turn sequence

{
  sub dxdy_to_dir6 {
    my ($dx,$dy) = @_;
    if ($dy == 0) {
      if ($dx == 2) { return 0; }
      if ($dx == -2) { return 3; }
    }
    if ($dy == 1) {
      if ($dx == 1) { return 1; }
      if ($dx == -1) { return 2; }
    }
    if ($dy == -1) {
      if ($dx == 1) { return 5; }
      if ($dx == -1) { return 4; }
    }
    die "unrecognised $dx,$dy";
  }

  # total 1s left 2s right base 4 digits
  sub calc_n_to_dir {
    my ($n) = @_;
    my $dir = 0;
    while ($n) {
      my $digit = $n % 4;
      if ($digit == 1) { $dir++; }
      if ($digit == 2) { $dir--; }
      $n = int($n/4);
    }
    return $dir;
  }

  # lowest non-zero base 4 digit
  sub calc_n_to_turn {
    my ($n) = @_;
    for (;;) {
      if ($n == 0) { die "oops n=0"; }
      my $digit = $n % 4;
      if ($digit == 1) { return 1; }
      if ($digit == 2) { return -2; }
      if ($digit == 3) { return 1; }
      $n = int($n/4);
    }
  }

  my $path = Math::PlanePath::KochCurve->new;
  my $n = $path->n_start;
  my $bad = 0;

  my ($prev_x, $prev_y) = $path->n_to_xy($n++);

  my ($x, $y) = $path->n_to_xy($n);
  my $prev_dx = $x - $prev_x;
  my $prev_dy = $y - $prev_y;
  my $prev_dir = dxdy_to_dir6($prev_dx,$prev_dy);

  while ($n < 1000) {
    my ($next_x,$next_y) = $path->n_to_xy($n+1);
    my $dx = $next_x - $x;
    my $dy = $next_y - $y;
    my $dir = dxdy_to_dir6($dx,$dy);

    my $got_turn = ($dir - $prev_dir) % 6;
    my $want_turn = calc_n_to_turn($n) % 6;
    if ($got_turn != $want_turn) {
      MyTestHelpers::diag ("n=$n turn got=$got_turn want=$want_turn");
      MyTestHelpers::diag ("  dir=$dir prev_dir=$prev_dir");
      last if $bad++ > 10;
    }

    my $got_dir = $dir % 6;
    my $want_dir = calc_n_to_dir($n) % 6;
    if ($got_dir != $want_dir) {
      MyTestHelpers::diag ("n=$n dir got=$got_dir want=$want_dir");
      last if $bad++ > 10;
    }

    $n++;
    $prev_dir = $dir;
    $x = $next_x;
    $y = $next_y;

  }
  ok ($bad, 0, "turn/dir sequence");
}

exit 0;
