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
use List::Util 'min','max';
use Test;
plan tests => 289;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
# use Smart::Comments;

require Math::PlanePath::CCurve;

my $path = Math::PlanePath::CCurve->new;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 127;
  ok ($Math::PlanePath::CCurve::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::CCurve->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::CCurve->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::CCurve->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# xyxy_to_n_list()

{
  my @data = (
              [ -2,3, -2,2, [7] ],
              [ -2,2, -2,3, [8] ],
             );
  foreach my $elem (@data) {
    my ($x1,$y1, $x2,$y2, $want_n_aref) = @$elem;
    my $want_n_str = join(',', @$want_n_aref);
    {
      my @got_n_list = $path->xyxy_to_n_list($x1,$y1, $x2,$y2);
      ok (scalar(@got_n_list), scalar(@$want_n_aref),
          "xyxy_to_n_list($x1,$y1, $x2,$y2) length");
      my $got_n_str = join(',', @got_n_list);
      ok ($got_n_str, $want_n_str,
          "xyxy_to_n_list($x1,$y1, $x2,$y2) values");
    }
    {
      my $got_n = $path->xyxy_to_n($x1,$y1, $x2,$y2);
      ok ($got_n, $want_n_aref->[0]);
    }
    {
      my @got_n = $path->xyxy_to_n($x1,$y1, $x2,$y2);
      ok (scalar(@got_n), 1);
      ok ($got_n[0], $want_n_aref->[0]);
    }
  }
}
{
  my @data = (
              [ -2,3, -2,2, [7,8] ],
              [ -2,2, -2,3, [7,8] ],
             );
  foreach my $elem (@data) {
    my ($x1,$y1, $x2,$y2, $want_n_aref) = @$elem;
    my $want_n_str = join(',', @$want_n_aref);
    {
      my @got_n_list = $path->xyxy_to_n_list_either($x1,$y1, $x2,$y2);
      ok (scalar(@got_n_list), scalar(@$want_n_aref),
          "xyxy_to_n_list_either($x1,$y1, $x2,$y2) length");
      my $got_n_str = join(',', @got_n_list);
      ok ($got_n_str, $want_n_str,
          "xyxy_to_n_list_either($x1,$y1, $x2,$y2) values");
    }
    {
      my $got_n = $path->xyxy_to_n_either($x1,$y1, $x2,$y2);
      ok ($got_n, $want_n_aref->[0]);
    }
    {
      my @got_n = $path->xyxy_to_n_either($x1,$y1, $x2,$y2);
      ok (scalar(@got_n), 1);
      ok ($got_n[0], $want_n_aref->[0]);
    }
  }
}



#------------------------------------------------------------------------------
# xy_to_n_list()

{
  my @data = (
              # close points
              [ -2,-2, [] ],
              [ -2,-1, [] ],
              [ -2,0, [] ],
              [ -2,1, [] ],
              [ -2,2, [8] ],

              [ -1,-2, [] ],
              [ -1,-1, [] ],
              [ -1,0, [] ],
              [ -1,1, [] ],
              [ -1,2, [] ],

              [ 0,-2, [] ],
              [ 0,-1, [] ],
              [ 0,0, [0] ],
              [ 0,1, [] ],
              [ 0,2, [4] ],

              [ 1,-2, [] ],
              [ 1,-1, [] ],
              [ 1,0, [1] ],
              [ 1,1, [2] ],
              [ 1,2, [3] ],

              [ 2,-2, [] ],
              [ 2,-1, [] ],
              [ 2,0, [] ],
              [ 2,1, [] ],
              [ 2,2, [] ],

              # doubled, tripled, quadrupled from the POD
              [  -2,  3, [7,9] ],
              [  18, -7, [189, 279, 281] ],
              [ -32, 55, [1727, 1813, 2283, 2369] ],
             );
  foreach my $elem (@data) {
    my ($x,$y, $want_n_aref) = @$elem;
    my $want_n_str = join(',', @$want_n_aref);
    {
      my @got_n_list = $path->xy_to_n_list($x,$y);
      ok (scalar(@got_n_list), scalar(@$want_n_aref),
          "xy_to_n_list($x,$y) length");
      my $got_n_str = join(',', @got_n_list);
      ok ($got_n_str, $want_n_str,
          "xy_to_n_list($x,$y) values");
    }
    {
      my $got_n = $path->xy_to_n($x,$y);
      ok ($got_n, $want_n_aref->[0]);
    }
    {
      my @got_n = $path->xy_to_n($x,$y);
      ok (scalar(@got_n), 1);
      ok ($got_n[0], $want_n_aref->[0]);
    }
  }
}

#------------------------------------------------------------------------------
# extents claimed in the POD

{
  my @want_h = (0,1,3,7,15,31);
  my @want_w = (0,0,1,3, 7,15);
  my @want_l = (0,0,0,1, 3, 7);
  foreach my $k (0 .. $#want_h) {
    my $rot = $k % 4;
    my $len = 2**$k;
    my $l = 0;
    my $w1 = 0;
    my $w2 = 0;
    my $h = 0;
    ### $rot
    ### $len

    foreach my $n (0 .. 4**$k) {
      my ($x,$y) = $path->n_to_xy ($n);
      ### at: "$x,$y  n=$n"

      foreach (1 .. $rot) {
        ($x,$y) = ($y,-$x);  # rotate -90
      }
      ### rotated: "$x,$y"
      # now endpoints X=0,Y=0 to X=2^k,Y=0 and going into Y negative

      $l = max($l,$y);
      $h = max($h,-$y);
      $w1 = max($w1,-$x);
      $w2 = max($w2,$x-$len);
    }

    ok ($h == $want_h[$k], 1, "h[$k]");
    ok ($l == $want_l[$k], 1);
    ok ($w1 == $want_w[$k], 1);
    ok ($w2 == $want_w[$k], 1);
  }
}

#------------------------------------------------------------------------------
# first few values

{
  my @data = ([ 0,    0,0 ],
              [ 0.25, 0.25,0 ],
              [ 0.75, 0.75,0 ],
              [ 1,    1,0 ],
              [ 1.25, 1,0.25 ],
              [ 1.75, 1,0.75 ],
              [ 2,    1,1 ],
              [ 3,    1,2 ],
              [ 4,    0,2 ],
              [ 5,    0,3 ],
              [ 6,    -1,3 ],
              [ 7,    -2,3 ],
              [ 8,    -2,2 ],
              [ 9,    -2,3 ],

             );
  my $path = Math::PlanePath::CCurve->new;
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    {
      my ($got_x, $got_y) = $path->n_to_xy ($n);
      ok ($got_x == $want_x, 1, "x at n=$n");
      ok ($got_y == $want_y, 1, "y at n=$n");
    }
    {
      my ($next_x, $next_y) = $path->n_to_xy ($n+1);
      my $want_dx = $next_x - $want_x;
      my $want_dy = $next_y - $want_y;
      my ($got_dx, $got_dy) = $path->n_to_dxdy ($n);
      ok ($got_dx == $want_dx, 1, "dx at n=$n");
      ok ($got_dy == $want_dy, 1, "dy at n=$n");
    }
  }

  # foreach my $elem (@data) {
  #   my ($want_n, $x, $y) = @$elem;
  #   next unless $want_n == int($want_n);
  #   my $got_n = $path->xy_to_n ($x, $y);
  #   ok ($got_n, $want_n, "n at x=$x,y=$y");
  # }
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative() instance method');
  ok ($path->y_negative, 1, 'y_negative() instance method');
  ok ($path->class_x_negative, 1, 'class_x_negative()');
  ok ($path->class_y_negative, 1, 'class_y_negative()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::CCurve->parameter_info_list;
  ok (join(',',@pnames), ''); # no arms yet
}


#------------------------------------------------------------------------------
# random n_to_dxdy()

{
  my $path = Math::PlanePath::CCurve->new;
  # for (my $n = 1.25; $n < 40; $n++) {
  foreach (1 .. 10) {
    my $bits = int(rand(25));     # 0 to 25, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive
    $n += random_quarter();

    my ($x,$y) = $path->n_to_xy ($n);
    my ($next_x,$next_y) = $path->n_to_xy ($n+1);
    my $delta_dx = $next_x - $x;
    my $delta_dy = $next_y - $y;

    my ($func_dx,$func_dy) = $path->n_to_dxdy ($n);
    if ($func_dx == 0) { $func_dx = '0'; } # avoid -0 in perl 5.6
    if ($func_dy == 0) { $func_dy = '0'; } # avoid -0 in perl 5.6

    ok ($func_dx, $delta_dx, "n_to_dxdy($n) dx at xy=$x,$y");
    ok ($func_dy, $delta_dy, "n_to_dxdy($n) dy at xy=$x,$y");
  }
}

# return 0, 0.25, 0.5 or 0.75
sub random_quarter {
  int(rand(4)) / 4;
}

#------------------------------------------------------------------------------
# turn sequence claimed in the pod

{
  my $bad = 0;
  my $n_start = $path->n_start;
 OUTER: foreach my $n ($n_start .. 500) {
    {
      my $path_dir = path_n_dir ($path, $n);
      my $calc_dir = calc_n_dir ($n);
      if ($path_dir != $calc_dir) {
        MyTestHelpers::diag ("dir n=$n  path $path_dir calc $calc_dir");
        last OUTER if $bad++ > 10;
      }
    }
    if ($n > $n_start) {  # turns from N=1 onwards
      {
        my $path_turn = path_n_turn ($path, $n);
        my $calc_turn = calc_n_turn ($n);
        if ($path_turn != $calc_turn) {
          MyTestHelpers::diag ("turn n=$n  path $path_turn calc $calc_turn");
          last OUTER if $bad++ > 10;
        }
      }
      {
        my $path_turn = path_n_turn ($path, $n+1);
        my $calc_turn = calc_n_next_turn ($n);
        if ($path_turn != $calc_turn) {
          MyTestHelpers::diag ("next turn n=$n  path $path_turn calc $calc_turn");
          last OUTER if $bad++ > 10;
        }
      }
    }
  }
  ok ($bad, 0, "turn sequence");
}

# with Y reckoned increasing upwards
sub dxdy_to_dir4 {
  my ($dx, $dy) = @_;
  if ($dx > 0) { return 0; }  # east
  if ($dx < 0) { return 2; }  # west
  if ($dy > 0) { return 1; }  # north
  if ($dy < 0) { return 3; }  # south
}

# return 0=E,1=N,2=W,3=S
sub path_n_dir {
  my ($path, $n) = @_;
  my ($dx,$dy) = $path->n_to_dxdy($n) or die "Oops, no point at ",$n;
  return dxdy_to_dir4 ($dx, $dy);
}
# return 0,1,2,3 to the left
sub path_n_turn {
  my ($path, $n) = @_;
  my $prev_dir = path_n_dir ($path, $n-1);
  my $dir = path_n_dir ($path, $n);
  return ($dir - $prev_dir) & 3;
}

# return 0=E,1=N,2=W,3=S
sub calc_n_dir {
  my ($n) = @_;
  my $dir = 0;
  while ($n) {
    $dir += ($n % 2);  # count 1 bits
    $n = int($n/2);
  }
  return ($dir & 3);
}

# return 0,1,2,3 to the left
sub calc_n_turn {
  my ($n) = @_;
  return (1-count_low_0_bits($n)) & 3;
}
sub count_low_0_bits {
  my ($n) = @_;
  if ($n == 0) { die; }
  my $count = 0;
  until ($n % 2) {
    $count++;
    $n /= 2;
  }
  return $count;
}

# return 0,1,2,3 to the left
sub calc_n_next_turn {
  my ($n) = @_;
  return (1-count_low_1_bits($n)) & 3;
}
sub count_low_1_bits {
  my ($n) = @_;
  my $count = 0;
  while ($n % 2) {
    $count++;
    $n = int($n/2);
  }
  return $count;
}


#------------------------------------------------------------------------------
# random rect_to_n_range()

{
  for (1 .. 5) {
    my $bits = int(rand(25));     # 0 to 25, inclusive
    my $n = int(rand(2**$bits));  # 0 to 2^bits, inclusive

    my ($x,$y) = $path->n_to_xy ($n);

    my $rev_n = $path->xy_to_n ($x,$y);
    ok (defined $rev_n, 1,
        "xy_to_n($x,$y) reverse n=$n, got undef");

    my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
    ok ($n_lo <= $n, 1,
        "rect_to_n_range() n=$n at xy=$x,$y cf got n_lo=$n_lo");
    ok ($n_hi >= $n, 1,
        "rect_to_n_range() n=$n at xy=$x,$y cf got n_hi=$n_hi");
  }
}


#------------------------------------------------------------------------------
exit 0;
