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
plan tests => 3485;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::AlternatePaper;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 127;
  ok ($Math::PlanePath::AlternatePaper::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::AlternatePaper->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::AlternatePaper->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::AlternatePaper->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::AlternatePaper->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# first few values

{
  my @data = ([ 0,      0, 0 ],
              [ 0.25,   0.25, 0 ],
              [ 0.75,   0.75, 0 ],
              [ 1,      1, 0 ],
              [ 1.25,   1, 0.25 ],
              [ 1.75,   1, 0.75 ],
              [ 2,      1, 1 ],
              [ 2.25,   1.25, 1 ],
              [ 2.75,   1.75, 1 ],
              [ 3,      2, 1 ],
              [ 3.25,   2, 0.75 ],
              [ 3.75,   2, 0.25 ],
              [ 4,      2, 0 ],
             );
  my $path = Math::PlanePath::AlternatePaper->new;
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    ok ($got_x, $want_x, "x at n=$n");
    ok ($got_y, $want_y, "y at n=$n");
  }

  foreach my $elem (@data) {
    my ($want_n, $x, $y) = @$elem;
    next unless $want_n == int($want_n);
    my $got_n = $path->xy_to_n ($x, $y);
    ok ($got_n, $want_n, "n at x=$x,y=$y");
  }
}

#------------------------------------------------------------------------------
# n_to_xy() fracs

foreach my $arms (1 .. 8) {
  my $path = Math::PlanePath::AlternatePaper->new (arms => $arms);
  foreach my $n (0 .. 64) {
    my ($x1,$y1) = $path->n_to_xy ($n);
    my ($x2,$y2) = $path->n_to_xy ($n+$arms);

    foreach my $frac (0.25, 0.5, 0.75) {
      my $want_xf = $x1 + ($x2-$x1)*$frac;
      my $want_yf = $y1 + ($y2-$y1)*$frac;

      my $nf = $n + $frac;
      my ($got_xf,$got_yf) = $path->n_to_xy ($nf);

      ok ($got_xf == $want_xf, 1, "n_to_xy($nf) arms=$arms frac $frac, x");
      ok ($got_yf == $want_yf, 1, "n_to_xy($nf) arms=$arms frac $frac, y");
    }
  }
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  my $path = Math::PlanePath::AlternatePaper->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative ? 1 : 0, 0, 'x_negative() instance method');
  ok ($path->y_negative ? 1 : 0, 0, 'y_negative() instance method');
  ok ($path->class_x_negative, 1, 'class_x_negative()');
  ok ($path->class_y_negative, 1, 'class_y_negative()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::AlternatePaper->parameter_info_list;
  ok (join(',',@pnames), 'arms');
}

{
  my $path = Math::PlanePath::AlternatePaper->new (arms => 2);
  ok ($path->x_negative ? 1 : 0, 0, 'x_negative() instance method');
  ok ($path->y_negative ? 1 : 0, 0, 'y_negative() instance method');
}
{
  my $path = Math::PlanePath::AlternatePaper->new (arms => 3);
  ok ($path->x_negative ? 1 : 0, 1, 'x_negative() instance method');
  ok ($path->y_negative ? 1 : 0, 0, 'y_negative() instance method');
}
{
  my $path = Math::PlanePath::AlternatePaper->new (arms => 4);
  ok ($path->x_negative ? 1 : 0, 1, 'x_negative() instance method');
  ok ($path->y_negative ? 1 : 0, 0, 'y_negative() instance method');
}
{
  my $path = Math::PlanePath::AlternatePaper->new (arms => 5);
  ok ($path->x_negative ? 1 : 0, 1, 'x_negative() instance method');
  ok ($path->y_negative ? 1 : 0, 1, 'y_negative() instance method');
}
{
  my $path = Math::PlanePath::AlternatePaper->new (arms => 8);
  ok ($path->x_negative ? 1 : 0, 1, 'x_negative() instance method');
  ok ($path->y_negative ? 1 : 0, 1, 'y_negative() instance method');
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
  # return 1 for left, 0 for right
  sub path_n_turn {
    my ($path, $n) = @_;
    my $prev_dir = path_n_dir ($path, $n-1);
    my $dir = path_n_dir ($path, $n);
    my $turn = ($dir - $prev_dir) % 4;
    if ($turn == 1) { return 1; } # left
    if ($turn == 3) { return 0; } # right
    die "Oops, unrecognised turn";
  }

  # return 1 for left, 0 for right
  sub calc_n_turn {
    my ($n) = @_;
    die if $n == 0;

    my $pos = 0;
    while (($n % 2) == 0) {
      $n = int($n/2); # skip low 0s
      $pos++;
    }
    $n = int($n/2);   # skip lowest 1
    $pos++;
    return ($n % 2) ^ ($pos % 2);  # next bit and its pos are the turn
  }

  # return 1 for left, 0 for right
  sub calc_n_next_turn {
    my ($n) = @_;
    die if $n == 0;

    my $pos = 0;
    while (($n % 2) == 1) {
      $n = int($n/2); # skip low 1s
      $pos++;
    }
    $n = int($n/2);   # skip lowest 0
    $pos++;
    return ($n % 2) ^ ($pos % 2);  # next bit and its pos are the turn
  }

  my $bad = 0;
  my $path = Math::PlanePath::AlternatePaper->new;
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
# xy_to_n_list()

{
  my @groups = ([ 1,   # arms=1
                  [ 0,1, [] ],
                  [ -1,0, [] ],
                  [ -1,-1, [] ],
                  [ 1,-1, [] ],

                  [ 0,0, [0] ],
                  [ 1,0, [1] ],
                  [ 1,1, [2] ],

                  [ 2,1, [3,7] ],
                  [ 2,0, [4] ],
                  [ 3,0, [5] ],
                  [ 3,1, [6,14] ],
                  # 2,1  7
                  [ 2,2, [8] ],
                  [ 3,2, [9,13] ],

                  [ 3,3, [10] ],

                  [ 4,3, [11,31] ],
                  [ 4,2, [12,28] ],
                  # 3,2  13
                  # 3,1  14
                  [ 4,1, [15,27] ],
                  [ 4,0, [16] ],
                  [ 5,0, [17] ],
                  [ 5,1, [18,26] ],
                  [ 6,1, [19,23] ],
                  [ 6,0, [20] ],
                  [ 7,0, [21] ],
                  [ 7,1, [22,62] ],

                  [ 4,4, [32] ],

                  [ 8,0, [64] ],
                  [ 9,0, [65] ],
                ],

                [ 2,   # arms=2
                  [ 0,1, [3] ],
                  [ -1,0, [] ],
                  [ -1,-1, [] ],
                  [ 1,-1, [] ],

                  [ 0,0, [0,1] ],
                  [ 1,0, [2] ],
                  [ 1,1, [4,5] ],

                  # [ 2,1, [3,7] ],
                  # [ 2,0, [4] ],
                  # [ 3,0, [5] ],
                  # [ 3,1, [6,14] ],
                  # # 2,1  7
                  # [ 2,2, [8] ],
                  # [ 3,2, [9,13] ],
                  #
                  # [ 3,3, [10] ],
                  #
                  # [ 4,3, [11,31] ],
                  # [ 4,2, [12,28] ],
                  # # 3,2  13
                  # # 3,1  14
                  # [ 4,1, [15,27] ],
                  # [ 4,0, [16] ],
                  # [ 5,0, [17] ],
                  # [ 5,1, [18,26] ],
                  # [ 6,1, [19,23] ],
                  # [ 6,0, [20] ],
                  # [ 7,0, [21] ],
                  # [ 7,1, [22,62] ],
                  #
                  # [ 4,4, [32] ],
                  #
                  # [ 8,0, [64] ],
                  # [ 9,0, [65] ],
                ],

                [ 3,   # arms=3
                  [ 0,0, [0,1] ],
                  [ 0,1, [2,4] ],
                  [ 1,0, [3]   ],
                  [ 1,1, [6,7] ],
                ],
               );
  foreach my $group (@groups) {
    my ($arms, @data) = @$group;
    my $path = Math::PlanePath::AlternatePaper->new (arms => $arms);

    foreach my $elem (@data) {
      my ($x,$y, $want_n_aref) = @$elem;
      my $want_n_str = join(',', @$want_n_aref);
      {
        my @got_n_list = $path->xy_to_n_list($x,$y);
        ok (scalar(@got_n_list), scalar(@$want_n_aref),
            "arms=$arms  xy=$x,$y");
        my $got_n_str = join(',', @got_n_list);
        ok ($got_n_str, $want_n_str);
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
}


#------------------------------------------------------------------------------
# random rect_to_n_range()

foreach my $arms (1 .. 8) {
  my $path = Math::PlanePath::AlternatePaper->new (arms => $arms);
  for (1 .. 5) {
    my $bits = int(rand(25));     # 0 to 25, inclusive
    my $n = int(rand(2**$bits));  # 0 to 2^bits, inclusive

    my ($x,$y) = $path->n_to_xy ($n);

    my $rev_n = $path->xy_to_n ($x,$y);
    ok (defined $rev_n, 1,
        "arms=$arms  xy_to_n($x,$y) reverse n, got undef");

    my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
    ok ($n_lo <= $n, 1,
        "rect_to_n_range() n=$n at xy=$x,$y cf got n_lo=$n_lo");
    ok ($n_hi >= $n, 1,
        "rect_to_n_range() n=$n at xy=$x,$y cf got n_hi=$n_hi");
  }
}



exit 0;
