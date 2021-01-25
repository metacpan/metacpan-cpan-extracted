#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
plan tests => 99;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::FilledRings;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 129;
  ok ($Math::PlanePath::FilledRings::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::FilledRings->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::FilledRings->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::FilledRings->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  my $path = Math::PlanePath::FilledRings->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
  ok ($path->class_x_negative, 1, 'class_x_negative()');
  ok ($path->class_y_negative, 1, 'class_y_negative()');
  ok ($path->n_frac_discontinuity, 0, 'n_frac_discontinuity()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::FilledRings->parameter_info_list;
  ok (join(',',@pnames), 'n_start');
}

#------------------------------------------------------------------------------
# _cumul_extend()

sub cumul_calc {
  my ($r) = @_;
  my $sq = ($r+.5)**2;
  my $count = 0;
  foreach my $x (-$r-1 .. $r+1) {
    my $x2 = $x*$x;
    foreach my $y (-$r-1 .. $r+1) {
      $count += ($x2 + $y*$y <= $sq);
    }
  }
  return $count;
}

{
  my $path = Math::PlanePath::FilledRings->new;
  foreach my $r (0 .. 50) {
    my $want = cumul_calc($r);
    Math::PlanePath::FilledRings::_cumul_extend($path);
    my $got = $path->{'cumul'}->[$r];
    ok ($got, $want, "r=$r");
  }
}

#------------------------------------------------------------------------------
# n_to_xy

{
  my @data = ([ 1, 0,0 ],
              [ 1.25, 0.25, 0 ],
              [ 1.75, 0.75, 0 ],

              [ 2, 1,0 ],
              [ 2.25, 1, 0.25 ],

              [ 3, 1,1 ], # top
              [ 3.25, 0.75, 1 ],

              [ 9,    1, -1 ],
              [ 9.25, 1, -0.75 ],
              [ 10,   2, 0 ],

              [ 14,  -1,2 ],
              [ 14.25,  -1.25, 1.75 ],

              [ 21.25,  2, -0.75 ],
              [ 37.25,  3, -0.75 ],
              [ 38,     4, 0 ],
             );
  my $path = Math::PlanePath::FilledRings->new;
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    ok ($got_x, $want_x, "x at n=$n");
    ok ($got_y, $want_y, "y at n=$n");
  }

  foreach my $elem (@data) {
    my ($want_n, $x, $y) = @$elem;
    if ($want_n == int($want_n)) {
      my $got_n = $path->xy_to_n ($x, $y);
      ok ($got_n, $want_n, "n at x=$x,y=$y");
    }
  }
}

#------------------------------------------------------------------------------
exit 0;


