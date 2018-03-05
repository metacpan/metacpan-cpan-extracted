#!/usr/bin/perl -w

# Copyright 2018 Kevin Ryde

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
plan tests => 120;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::AlternateTerdragon;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::AlternateTerdragon::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::AlternateTerdragon->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::AlternateTerdragon->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::AlternateTerdragon->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::AlternateTerdragon->new;
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
  my $path = Math::PlanePath::AlternateTerdragon->new;
  ok ($path->n_start, 0, 'n_start()');
  ok (! $path->x_negative, 1, 'x_negative()');
  ok (  $path->y_negative, 1, 'y_negative()');
  ok ($path->class_x_negative, 1, 'class_x_negative()');
  ok ($path->class_y_negative, 1, 'class_y_negative()');
}
{
  my $path = Math::PlanePath::AlternateTerdragon->new (arms => 2);
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::AlternateTerdragon->parameter_info_list;
  ok (join(',',@pnames), 'arms');
}


#------------------------------------------------------------------------------
# xy_to_n_list()

# at 0,0
foreach my $arms (1 .. 6) {
  my $path = Math::PlanePath::AlternateTerdragon->new (arms => $arms);
  my @got_n_list = $path->xy_to_n_list(0,0);
  my $got_n_list = join(',',@got_n_list);
  my $want_n_list = join(',', 0 .. $arms-1);
  ok ($got_n_list, $want_n_list);
}

{
  # arms=6 points shown in the POD
  #
  #             --- 7,8,26 ---------------- 1,12,19 ---
  #               /        \               /         \
  #  \           /          \             /           \          /
  #   \         /            \           /             \        /
  # --- 3,14,21 ------------- 0/1/2/3/4/5 -------------- 6,11,24 ---
  #   /         \            /           \             /        \
  #  /           \          /             \           /          \
  #               \        /               \         /
  #            --- 9,10,28 ---------------- 5,16,23 ---

  my $path = Math::PlanePath::AlternateTerdragon->new (arms => 6);
  foreach my $elem ([ 0, 0, '0,1,2,3,4,5'],
                    [ 2, 0, '6,11,24'],
                    [ 1, 1, '1,12,19'],
                    [-1, 1, '7,8,26'],
                    [-2, 0, '3,14,21'],
                    [-1,-1, '9,10,28'],
                    [ 1,-1, '5,16,23'],
                   ) {
    my ($x,$y, $want_n_list) = @$elem;
    my @got_n_list = $path->xy_to_n_list($x,$y);
    my $got_n_list = join(',',@got_n_list);
    ok ($got_n_list, $want_n_list);
  }
}


#------------------------------------------------------------------------------
# n_to_dxdy()

{
  my $path = Math::PlanePath::AlternateTerdragon->new (arms => 2);
  my $arms_count = $path->arms_count;
  ok ($arms_count, 2);

  my $n = 1;
  my ($x,$y) = $path->n_to_xy($n);
  ok ($x, 0);
  ok ($y, 0);

  my ($x2,$y2) = $path->n_to_xy($n + $arms_count);
  ok ($x2, 1);
  ok ($y2, 1);

  my ($dx,$dy) = $path->n_to_dxdy($n);
  ok ($dx, 1);
  ok ($dy, 1);
}

{
  my $path = Math::PlanePath::AlternateTerdragon->new;
  #   1      2
  #           \
  #            *
  #             \
  # Y=0  0---*---1
  #    X=0   1   2
  my $n = .5;

  my ($x,$y) = $path->n_to_xy($n);
  ok ($x, 1);
  ok ($y, 0);

  my ($x2,$y2) = $path->n_to_xy($n+1);
  ok ($x2, 1.5);
  ok ($y2, .5);

  my ($dx,$dy) = $path->n_to_dxdy($n);
  ok ($dx, 1.5 - 1);
  ok ($dy, .5 - 0);
}
{
  my $path = Math::PlanePath::AlternateTerdragon->new;
  #   1      2------3
  #           \
  #            \
  #             *
  # Y=0  0-------1
  #    X=0   1   2
  my $n = 1.25;

  my ($x,$y) = $path->n_to_xy($n);
  ok ($x, 1.75);
  ok ($y, .25);

  my ($x2,$y2) = $path->n_to_xy($n+1);
  ok ($x2, 1.5);
  ok ($y2, 1);

  my ($dx,$dy) = $path->n_to_dxdy($n);
  ok ($dx, 1.5 - 1.75);
  ok ($dy, 1 - .25);
}
{
  my $path = Math::PlanePath::AlternateTerdragon->new;
  #   1      2---*---3
  #           \     /
  #            *   *
  #             \ /
  # Y=0  0---*---1
  #    X=0   1   2  3  4
  my $n = 2.5;

  my ($x,$y) = $path->n_to_xy($n);
  ok ($x, 2);
  ok ($y, 1);

  my ($x2,$y2) = $path->n_to_xy($n+1);
  ok ($x2, 2.5);
  ok ($y2, .5);

  my ($dx,$dy) = $path->n_to_dxdy($n);
  ok ($dx, 2.5 - 2);
  ok ($dy, .5 - 1);
}


#------------------------------------------------------------------------------
# xy_to_n_list()

{
  #   1      2-------3
  #           \     /
  #            \   /
  #             \ /
  # Y=0  0------1,4
  #    X=0   1   2

  {
    my $path = Math::PlanePath::AlternateTerdragon->new;
    my @n_list = $path->xy_to_n_list(2,0);
    ok (join(',',@n_list), '1,4');
  }
  {
    my $path = Math::PlanePath::AlternateTerdragon->new (arms => 2);
    my @n_list = $path->xy_to_n_list(2,0);
    ok (join(',',@n_list), '2,8');
  }
}

#------------------------------------------------------------------------------
# random rect_to_n_range()

foreach my $arms (1 .. 4) {
  my $path = Math::PlanePath::AlternateTerdragon->new (arms => $arms);
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
exit 0;
