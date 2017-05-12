#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
plan tests => 1576;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::GosperSide;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 124;
  ok ($Math::PlanePath::GosperSide::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::GosperSide->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::GosperSide->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::GosperSide->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::GosperSide->new;
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
  my $path = Math::PlanePath::GosperSide->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
}


#------------------------------------------------------------------------------
# first few points

{
  my @data = (
              [ .25,  .5, 0 ],
              [ .5,    1, 0 ],
              [ 1.75,  2.75, .75 ],

              [ 0, 0,0 ],
              [ 1, 2,0 ],
              [ 2, 3,1 ],

              [ 3, 5,1 ],
              [ 4, 6,2 ],
              [ 5, 5,3 ],

              [ 6, 6,4 ],
              [ 7, 8,4 ],
              [ 8, 9,5 ],

              [ 9, 11,5 ],
             );
  my $path = Math::PlanePath::GosperSide->new;
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
# rect_to_n_range()

{
  my $path = Math::PlanePath::GosperSide->new;
  my ($n_lo, $n_hi) = $path->rect_to_n_range(0,0, 0,0);
  ok ($n_lo == 0, 1, "rect_to_n_range() 0,0  n_lo=$n_lo");
  ok ($n_hi >= 0, 1, "rect_to_n_range() 0,0  n_hi=$n_hi");
}


#------------------------------------------------------------------------------
# random points

{
  my $path = Math::PlanePath::GosperSide->new;
  for (1 .. 500) {
    my $bits = int(rand(25));         # 0 to 25, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive

    my ($x,$y) = $path->n_to_xy ($n);
    my $rev_n = $path->xy_to_n ($x,$y);
    if (! defined $rev_n) { $rev_n = 'undef'; }
    ok ($rev_n, $n, "xy_to_n($x,$y) reverse to expect n=$n, got $rev_n");

    my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
    ok ($n_lo <= $n, 1, "rect_to_n_range() reverse n=$n cf n_lo=$n_lo");
    ok ($n_hi >= $n, 1, "rect_to_n_range() reverse n=$n cf n_hi=$n_hi");
  }
}

#------------------------------------------------------------------------------
# turn sequence described in the POD

{
  # 1 for +60 deg, -1 for -60 deg
  sub n_to_turn_calculated {
    my ($n) = @_;
    for (;;) {
      if ($n == 0) { die "oops n=0"; }
      my $mod = $n % 3;
      if ($mod == 1) { return 1; }
      if ($mod == 2) { return -1; }
      $n = int($n/3);
    }
  }

  sub dxdy_to_dir {
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

  my $path = Math::PlanePath::GosperSide->new;
  my $n = $path->n_start;
  my $bad = 0;

  my ($prev_x, $prev_y) = $path->n_to_xy($n++);

  my ($x, $y) = $path->n_to_xy($n++);
  my $dx = $x - $prev_x;
  my $dy = $y - $prev_y;
  my $prev_dir = dxdy_to_dir($dx,$dy);

  while ($n < 1000) {
    $prev_x = $x;
    $prev_y = $y;

    ($x,$y) = $path->n_to_xy($n);
    $dx = $x - $prev_x;
    $dy = $y - $prev_y;
    my $dir = dxdy_to_dir($dx,$dy);

    my $got_turn = ($dir - $prev_dir + 6) % 6;
    my $want_turn = n_to_turn_calculated($n-1) % 6;
    if ($want_turn < 0) { $want_turn += 6; }

    if ($got_turn != $want_turn) {
      MyTestHelpers::diag ("n=$n turn got=$got_turn want=$want_turn");
      MyTestHelpers::diag ("  dir=$dir prev_dir=$prev_dir");
      last if $bad++ > 10;
    }

    $n++;
    $prev_dir = $dir;
  }
  ok ($bad, 0, "turn sequence");
}

#------------------------------------------------------------------------------
# total turn described in the POD

{
  # as a count of +60 deg
  sub n_to_dir_calculated {
    my ($n) = @_;
    my $dir = 0;
    while ($n) {
      if (($n % 3) == 1) {
        $dir++;
      }
      $n = int($n/3);
    }
    return $dir;
  }

  my $path = Math::PlanePath::GosperSide->new;
  my $n = $path->n_start;
  my $bad = 0;
  my ($x,$y) = $path->n_to_xy($n);

  while ($n < 1000) {
    my ($next_x,$next_y) = $path->n_to_xy($n+1);
    my $dx = $next_x - $x;
    my $dy = $next_y - $y;
    my $path_dir = dxdy_to_dir($dx,$dy);
    my $calc_dir = n_to_dir_calculated($n) % 6;

    if ($path_dir != $calc_dir) {
      MyTestHelpers::diag ("n=$n dir path=$path_dir calc=$calc_dir");
      MyTestHelpers::diag ("  xy from $x,$y to $next_x,$next_y");
      last if $bad++ > 10;
    }

    $x = $next_x;
    $y = $next_y;
    $n++;
  }
  ok ($bad, 0, "total turn");
}

exit 0;
