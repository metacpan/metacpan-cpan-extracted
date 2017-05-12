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
plan tests => 1254;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::SierpinskiCurve;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 124;
  ok ($Math::PlanePath::SierpinskiCurve::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::SierpinskiCurve->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::SierpinskiCurve->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::SierpinskiCurve->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::SierpinskiCurve->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# n_start()

{
  my $path = Math::PlanePath::SierpinskiCurve->new();
  ok ($path->n_start, 0, 'n_start()');
}

#------------------------------------------------------------------------------
# x_negative(), y_negative()

{
  foreach my $elem ([1, 0,0],
                    [2, 0,0],
                    [3, 1,0],
                    [4, 1,0],
                    [5, 1,1],
                    [6, 1,1],
                    [7, 1,1],
                    [8, 1,1]) {
    my ($arms, $want_x_negative, $want_y_negative) = @$elem;
    my $path = Math::PlanePath::SierpinskiCurve->new (arms => $arms);
    ok (!!$path->x_negative, !!$want_x_negative, 'x_negative()');
    ok (!!$path->y_negative, !!$want_y_negative, 'y_negative()');
  }
}


#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::SierpinskiCurve->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 0); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 3); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 15); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(3);
    ok ($n_lo, 0);
    ok ($n_hi, 63); }
}
{
  my $path = Math::PlanePath::SierpinskiCurve->new (arms => 2);
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 1); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 7); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 31); }
}
{
  my $path = Math::PlanePath::SierpinskiCurve->new (arms => 8);
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 7); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 31); }
}

#------------------------------------------------------------------------------
# rect_to_n_range() samples

{
  foreach my $elem (

                    [7, 0,-1, 0,-2, 0,27 ],


                    # edges
                    [1, 0,0, 0,0,   1,0],

                    [2, 0,0, 0,0,   0,7],
                    [2, -100,0, -1,0, 1,0],

                    [3, -1,0, -1,0,  1,0],
                    [3, -1,1, -1,1,    0,11],
                    [3, -2,1, -2,1,    1,0],

                    [4, -2,1, -2,1,    0,15],
                    [4, -1,-1, -1,-1,  1,0],

                    [5, -2,-1, -2,-1,  0,19],
                    [5, 0,-2, 0,-2,    1,0],
                    [5, -1,-2, -1,-2,  1,0],

                    [6, -1,-2, -1,-2,    0,23],
                    [6, 0,-2, 0,-2,    1,0],

                    [7, 0,-2, 0,-2,    0,27],
                    [7, 1,-2, 1,-2,    1,0],

                    [8, 1,-2, 1,-2,    0,31],
                   ) {
    my ($arms, $x1,$y1,$x2,$y2, $want_n_lo,$want_n_hi) = @$elem;
    my $path = Math::PlanePath::SierpinskiCurve->new (arms => $arms);
    my ($n_lo, $n_hi) = $path->rect_to_n_range ($x1,$y1, $x2,$y2);
    ok ($n_hi, $want_n_hi, "arms=$arms  $x1,$y1, $x2,$y2");
    ok ($n_lo, $want_n_lo);
  }
}


#------------------------------------------------------------------------------
# rect_to_n_range() near origin

{
  my $bad = 0;
  foreach my $arms (1 .. 8) {
    my $path = Math::PlanePath::SierpinskiCurve->new (arms => $arms);
    foreach my $n (0 .. 8*$arms) {
      my ($x,$y) = $path->n_to_xy ($n);
      my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
      unless ($n_lo <= $n) {
        $bad++;
      }
      unless ($n_hi >= $n) {
        $bad++;
      }
    }
  }
  ok ($bad, 0);
}


#------------------------------------------------------------------------------
# first few points

{
  my @data = (

              [ 0.25,  1.25, 0.25 ],
              [ 1.25,  2.25, 1 ],
              [ 2.25,  3.25, 0.75 ],
              [ 3.25,  4.25, 0.25 ],
              [ 4.25,  4.75, 1.25 ],

              [ 0, 1,0 ],
              [ 1, 2,1 ],
              [ 2, 3,1 ],
              [ 3, 4,0 ],
              [ 4, 5,1 ],
             );
  my $path = Math::PlanePath::SierpinskiCurve->new;
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
# random rect_to_n_range()

foreach my $arms (1 .. 8) {
  my $path = Math::PlanePath::SierpinskiCurve->new (arms => $arms);
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
# random n_to_xy() fracs

foreach my $arms (1 .. 8) {
  my $path = Math::PlanePath::SierpinskiCurve->new (arms => $arms);
  for (1 .. 20) {
    my $bits = int(rand(25));         # 0 to 25, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive
    my $nhex = sprintf '0x%X', $n;

    my ($x1,$y1) = $path->n_to_xy ($n);
    my ($x2,$y2) = $path->n_to_xy ($n+$arms);

    foreach my $frac (0.25, 0.5, 0.75) {
      my $want_xf = $x1 + ($x2-$x1)*$frac;
      my $want_yf = $y1 + ($y2-$y1)*$frac;

      my $nf = $n + $frac;
      my ($got_xf,$got_yf) = $path->n_to_xy ($nf);

      ok ($got_xf, $want_xf,
          "n_to_xy($nf) arms=$arms frac $frac, X (n hex $nhex)");
      ok ($got_yf, $want_yf,
          "n_to_xy($nf) arms=$arms frac $frac, X (n hex $nhex)");
    }
  }
}


#------------------------------------------------------------------------------
# xy_to_n() near origin

{
  my $bad = 0;
 OUTER: foreach my $d (0 .. 4) {
    foreach my $s (0 .. 4) {
      foreach my $arms (1 .. 8) {
        my $path = Math::PlanePath::SierpinskiCurve->new
          (arms => $arms,
           straight_spacing => $s,
           diagonal_spacing => $d);

        foreach my $x (-8 .. 8) {
          foreach my $y (-8 .. 8) {
            my $n = $path->xy_to_n ($x,$y);
            next unless defined $n;
            my ($nx,$ny) = $path->n_to_xy ($n);

            if ($nx != $x || $ny != $y) {
              MyTestHelpers::diag("xy_to_n($x,$y) arms=$arms gives n=$n, which is $nx,$ny");
              last OUTER if ++$bad > 10;
            }
          }
        }
      }
    }
  }
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
# X axis base 4 digits 0 and 3 only

{
  my $path = Math::PlanePath::SierpinskiCurve->new;

  foreach my $i (0 .. 50) {
    my $x = 3*$i + 1;
    my $want_n = duplicate_bits($i);
    my $got_n = $path->xy_to_n ($x,0);
    ok ($got_n, $want_n, "i=$i N at X=$x,Y=0");
  }
}
sub duplicate_bits {
  my ($n) = @_;
  my $bits = sprintf '%b',$n;
  $bits =~ s/(.)/$1$1/g;
  return oct("0b$bits");
}

exit 0;
