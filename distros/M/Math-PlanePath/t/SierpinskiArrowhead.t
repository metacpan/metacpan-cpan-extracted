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
plan tests => 168;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::SierpinskiArrowhead;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 128;
  ok ($Math::PlanePath::SierpinskiArrowhead::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::SierpinskiArrowhead->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::SierpinskiArrowhead->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::SierpinskiArrowhead->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::SierpinskiArrowhead->new;
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
  my $path = Math::PlanePath::SierpinskiArrowhead->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
}


#------------------------------------------------------------------------------
# turn claimed in the POD

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
sub path_n_dir {
  my ($path, $n) = @_;
  my ($dx,$dy) = $path->n_to_dxdy($n) or die "Oops, no point at ",$n;
  return dxdy_to_dir6 ($dx, $dy);
}
# return +/- dir6
sub path_n_turn {
  my ($path, $n) = @_;
  my $prev_dir = path_n_dir ($path, $n-1);
  my $dir = path_n_dir ($path, $n);
  my $turn = ($dir - $prev_dir + 6) % 6;  # "+3" to stay +ve for "use integer"
  if ($turn >= 4) { $turn -= 6; }
  return $turn;
}

# return 1 for left, -1 for right
sub calc_n_turn {
  my ($n) = @_;
  my $ret = 1;  # left
  while ($n && ($n % 3) == 0) {
    $ret = -$ret;           # flip for low 0s
    $n = int($n/3);
  }
  $n = int($n/3);           # skip lowest non-0
  while ($n) {
    if (($n % 3) == 1) {
      $ret = -$ret;         # flip for all 1s
    }
    $n = int($n/3);
  }
  return $ret;
}

{
  my $path = Math::PlanePath::SierpinskiArrowhead->new;
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
  }
  ok ($bad, 0, "turn sequence");
}

sub LowestNonTwo {
  my ($n) = @_;
  while (($n % 3) == 2) { $n = int($n/3); }
  return $n % 3;
}
sub CountLowTwos {
  my ($n) = @_;
  my $ret = 0;
  while (($n % 3) == 2) { $n = int($n/3); $ret++; }
  return $ret;
}
# lowest non-2 and its position claimed in the POD
sub calc_m_even_is_right {
  my ($m) = @_;
  return (LowestNonTwo($m-1) + CountLowTwos($m-1)) % 2;
}
{
  my $path = Math::PlanePath::SierpinskiArrowhead->new;
  my $bad = 0;
  foreach my $m ($path->n_start + 1 .. 500) {
    my $n = 2*$m;
    my $path_turn = (path_n_turn ($path, 2*$m) == -1 ? 1 : 0);
    my $calc_turn = calc_m_even_is_right ($m);
    if ($path_turn != $calc_turn) {
      MyTestHelpers::diag ("turn n=2*$m  path $path_turn calc $calc_turn");
      last if $bad++ > 10;
    }
  }
  ok ($bad, 0, "turn sequence");
}

sub LowestNonOne {
  my ($n) = @_;
  while (($n % 3) == 1) { $n = int($n/3); }
  return $n % 3;
}
sub CountLowOnes {
  my ($n) = @_;
  my $ret = 0;
  while (($n % 3) == 1) { $n = int($n/3); $ret++; }
  return $ret;
}
# lowest non-2 and its position claimed in the POD
sub calc_m_odd_is_right {
  my ($m) = @_;
  return ((LowestNonOne($m)/2) + CountLowOnes($m)) % 2;
}
{
  my $path = Math::PlanePath::SierpinskiArrowhead->new;
  my $bad = 0;
  foreach my $m ($path->n_start + 1 .. 500) {
    my $n = 2*$m;
    my $path_turn = (path_n_turn ($path, 2*$m+1) == -1 ? 1 : 0);
    my $calc_turn = calc_m_odd_is_right ($m);
    if ($path_turn != $calc_turn) {
      MyTestHelpers::diag ("turn n=2*$m  path $path_turn calc $calc_turn");
      last if $bad++ > 10;
    }
  }
  ok ($bad, 0, "turn sequence");
}



#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::SierpinskiArrowhead->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 1); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 3); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 9); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(3);
    ok ($n_lo, 0);
    ok ($n_hi, 27); }
}


#------------------------------------------------------------------------------
# first few points

{
  my @data = ([ 0,  0,0 ],
              [ 1,  1,1 ],
              [ 2,  0,2 ],
              [ 3,  -2,2 ],

              [ .25,   .25, .25 ],
              [ 1.25,   .75, 1.25 ],
              [ 2.5,   -1, 2 ],
             );
  my $path = Math::PlanePath::SierpinskiArrowhead->new;
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
# xy_to_n() distinct n and all n

{
  my $path = Math::PlanePath::SierpinskiArrowhead->new;
  my $bad = 0;
  my @seen;
  my $xlo = -16;
  my $xhi = 16;
  my $ylo = 0;
  my $yhi = 16;
  my $count = 0;
  my ($nlo, $nhi) = $path->rect_to_n_range($xlo,$ylo, $xhi,$yhi);

 OUTER: for (my $x = $xlo; $x <= $xhi; $x++) {
    for (my $y = $ylo; $y <= $yhi; $y++) {
      my $n = $path->xy_to_n ($x,$y);
      if (! defined $n) {
        next;
      }
      if ($seen[$n]) {
        MyTestHelpers::diag ("x=$x,y=$y n=$n seen before at $seen[$n]");
        last if $bad++ > 10;
      }
      my ($rx,$ry) = $path->n_to_xy ($n);
      if ($rx != $x || $ry != $y) {
        MyTestHelpers::diag ("x=$x,y=$y n=$n goes back to rx=$rx ry=$ry");
        last OUTER if $bad++ > 10;
      }
      if ($n < $nlo) {
        MyTestHelpers::diag ("x=$x,y=$y n=$n below nlo=$nlo");
        last OUTER if $bad++ > 10;
      }
      if ($n > $nhi) {
        MyTestHelpers::diag ("x=$x,y=$y n=$n above nhi=$nhi");
        last OUTER if $bad++ > 10;
      }
      $seen[$n] = "$x,$y";
      $count++;
    }
  }
  foreach my $n (0 .. $#seen) {
    if (! defined $seen[$n]) {
      MyTestHelpers::diag ("n=$n not seen");
      last if $bad++ > 10;
    }
  }
  ok ($bad, 0, "xy_to_n() coverage, $count points");
}

#------------------------------------------------------------------------------
# random fracs

{
  my $path = Math::PlanePath::SierpinskiArrowhead->new;
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
exit 0;
