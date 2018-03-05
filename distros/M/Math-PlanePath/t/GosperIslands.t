#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
plan tests => 596;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::GosperIslands;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::GosperIslands::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::GosperIslands->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::GosperIslands->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::GosperIslands->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::GosperIslands->new;
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
  my $path = Math::PlanePath::GosperIslands->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
}


#------------------------------------------------------------------------------
# first few points

{
  my @data = (
              # [ .5,  -1.5, -.5 ],
              # [ 3.25,  1.25, -.25 ],
              # [ 3.75,  -3.25, -.25 ],
              #
              [ 1, 2,0 ],
              [ 2, 1,1 ],
              [ 3, -1,1 ],
              [ 4, -2,0 ],
              [ 5, -1,-1 ],
              [ 6, 1,-1 ],

              [  7, 5,1 ],
              [  8,  4,2 ],
              [  9,  2,2 ],
              [ 10, 1,3 ],
              [ 11,  -1,3 ],
              [ 12,  -2,2 ],
              [ 13, -4,2 ],
              [ 14,  -5,1 ],
              [ 15,  -4,0 ],

              [ 25, 11,5 ],

              # [ 9, 1,2 ],
              # [ 10, 3,2 ],
              # [ 11, 2,1 ],
              # [ 12, 3,0 ],
              #
              [ 33, -1,7 ],
             );
  my $path = Math::PlanePath::GosperIslands->new;
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
# xy_to_n() reverse n_to_xy()

{
  my $path = Math::PlanePath::GosperIslands->new;
  for (1 .. 500) {
    my $bits = int(rand(25));         # 0 to 25, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive
    my ($x,$y) = $path->n_to_xy ($n);
    my $rev_n = $path->xy_to_n ($x,$y);
    ok ($rev_n, $n, "xy_to_n() reverse n=$n");
  }
}


#------------------------------------------------------------------------------
# xy_to_n() distinct n

{
  my $path = Math::PlanePath::GosperIslands->new;
  my $bad = 0;
  my %seen;
  my $xlo = -50;
  my $xhi = 50;
  my $ylo = -50;
  my $yhi = 50;
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


exit 0;
