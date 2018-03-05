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
plan tests => 344;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::BetaOmega;
my $path = Math::PlanePath::BetaOmega->new;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::BetaOmega::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::BetaOmega->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::BetaOmega->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::BetaOmega->VERSION($check_version); 1 },
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
# n_start, x_negative, y_negative

{
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative() instance method');
  ok ($path->y_negative, 1, 'y_negative() instance method');
  ok ($path->class_x_negative, 0, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 1, 'class_y_negative() instance method');

  my @pnames = map {$_->{'name'}} $path->parameter_info_list;
  ok (join(',',@pnames), '', 'parameter_info_list() keys');
}


#------------------------------------------------------------------------------
# first few points

{
  my @data = ([ 0.25,   0, .25 ],
              [ 1.25,   .25, 1 ],
              [ 2.25,   1, .75 ],
              [ 3.25,   1, -.25 ],

              [ 4.25,   .75, -1 ],
              [ 5.25,   0, -1.25 ],
              [ 6.25,   .25, -2 ],
              [ 7.25,   1.25, -2 ],


              [ 0,  0,0 ],
              [ 1,  0,1 ],
              [ 2,  1,1 ],
              [ 3,  1,0 ],

              [ 4,  1,-1 ],
              [ 5,  0,-1 ],
              [ 6,  0,-2 ],
              [ 7,  1,-2 ],

              [ 32, 4,4 ],
              [ 33, 4,5 ],
              [ 34, 5,5 ],
              [ 35, 5,4 ],

              [ 96, 1,-7 ],
              [ 97, 0,-7 ],
              [ 98, 0,-8 ],
              [ 99, 1,-8 ],
             );
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
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
# _y_round_down_len_level()

foreach my $elem ([0, 1,0],
                  [1, 1,0],

                  [2, 4,2],
                  [3, 4,2],
                  [5, 4,2],

                  [6, 16,4],
                  [7, 16,4],
                  [21, 16,4],

                  [22, 64,6],
                  [23, 64,6],

                  [-1, 2,1],
                  [-2, 2,1],

                  [-3, 8,3],
                  [-4, 8,3],
                  [-10, 8,3],

                  [-11, 32,5],
                  [-12, 32,5],
                 ) {
  my ($y, $want_len, $want_level) = @$elem;

  my ($got_len, $got_level)
    = Math::PlanePath::BetaOmega::_y_round_down_len_level($y);
  ok ($got_len, $want_len, "len at y=$y");
  ok ($got_level, $want_level, "level at y=$y");
}


# No it's not simply from y_min.  The alternate up and down means it's a
# round towards y_max or y_min at alternate levels ...
#
# require Math::PlanePath::KochCurve;
# my $want_y_min = Y_min_pow($want_level);
# my ($based_len, $based_level)
#   = round_down_pow ($y - $want_y_min, 2);
# ok ($based_len, $want_len);
# ok ($based_level, $want_level);


#------------------------------------------------------------------------------
# Ymin / Ymax per docs

{
  sub floor {
    my ($x) = @_;
    return int($x);
  }
  sub ceil {
    my ($x) = @_;
    if ($x == int($x)) { return $x; }
    return int($x)+1;
  }
  sub Y_min_pow {
    my ($level) = @_;
    return - (4**floor($level/2) - 1) * 2 / 3;
  }
  sub Y_max_pow {
    my ($level) = @_;
    return (4**ceil($level/2) - 1) / 3;
  }

  sub Y_min_binary {
    my ($level) = @_;
    my $ret = 0;
    while (($level-=2) >= 0) {
      $ret <<= 1;
      $ret |= 1;
      $ret <<= 1;
    }
    return -$ret;
  }
  sub Y_max_binary {
    my ($level) = @_;
    my $ret = 0;
    $level++;
    while (($level-=2) >= 0) {
      $ret <<= 1;
      $ret <<= 1;
      $ret |= 1;
    }
    return $ret;
  }

  my $want_y_min = 0;
  my $want_y_max = 0;
  foreach my $level (1 .. 20) {
    if ($level & 1) {
      $want_y_max += 2**($level-1);
    } else {
      $want_y_min -= 2**($level-1);
    }

    # using "==" so that "-0" works in perl 5.6
    ok (Y_min_pow($level) == $want_y_min, 1, "level=$level Y min by pow");
    ok (Y_max_pow($level) == $want_y_max, 1, "level=$level Y max by pow");

    ok (Y_min_binary($level) == $want_y_min, 1, "level=$level Y min by binary");
    ok (Y_max_binary($level) == $want_y_max, 1, "level=$level Y max by binary");

  }
}


#------------------------------------------------------------------------------
# random fracs

{
  my $path = Math::PlanePath::BetaOmega->new;
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
# many fracs

{
  my $path = Math::PlanePath::BetaOmega->new;
  my ($x,$y) = $path->n_to_xy (0);
  my $bad = 0;
  my $pow = 5;
  for my $n (0 .. 4**$pow+5) {
    my ($x2,$y2) = $path->n_to_xy ($n+1);

    my $frac = 0.25;
    my $want_xf = $x + ($x2-$x)*$frac;
    my $want_yf = $y + ($y2-$y)*$frac;

    my $nf = $n + $frac;
    my ($got_xf,$got_yf) = $path->n_to_xy ($nf);

    if ($got_xf != $want_xf || $got_yf != $want_yf) {
      MyTestHelpers::diag ("wrong at n=$n  got $got_xf,$got_yf want $want_xf,$want_yf");
      if ($bad++ > 10) { last; }
    }
    ($x,$y) = ($x2,$y2);
  }
  ok ($bad, 0);
}



exit 0;
