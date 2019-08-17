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
plan tests => 6;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::FibonacciWordFractal;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 127;
  ok ($Math::PlanePath::FibonacciWordFractal::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::FibonacciWordFractal->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::FibonacciWordFractal->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::FibonacciWordFractal->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# xy_to_n() near origin

{
  my $bad = 0;
  my $path = Math::PlanePath::FibonacciWordFractal->new;
 OUTER:
  foreach my $x (-8 .. 16) {
    foreach my $y (-8 .. 16) {
      my $n = $path->xy_to_n ($x,$y);
      next unless defined $n;
      my ($nx,$ny) = $path->n_to_xy ($n);

      if ($nx != $x || $ny != $y) {
        MyTestHelpers::diag("xy_to_n($x,$y) gives n=$n, which is $nx,$ny");
        last OUTER if ++$bad > 10;
      }
    }
  }
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
# n_to_xy() fracs

{
  my $bad = 0;
  my $path = Math::PlanePath::FibonacciWordFractal->new;
  foreach my $n (0 .. 89) {
    my ($x1,$y1) = $path->n_to_xy ($n);
    my ($x2,$y2) = $path->n_to_xy ($n+1);
    my $want_x = $x1 + ($x2-$x1)*.25;
    my $want_y = $y1 + ($y2-$y1)*.25;

    my $n_frac = $n + .25;
    my ($got_x,$got_y) = $path->n_to_xy ($n_frac);

    if ($got_x != $want_x || $got_y != $want_y) {
      MyTestHelpers::diag("n_to_xy($n_frac) got $got_x,$got_y want $want_x,$want_y");
      last if ++$bad > 10;
    }
  }
  ok ($bad, 0);
}

exit 0;
