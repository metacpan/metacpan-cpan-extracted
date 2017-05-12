#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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
use List::Util 'min', 'max';
use Math::PlanePath::DragonCurve;

use Test;
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }


# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# rect_to_n_range() on various boxes

{
  require Math::PlanePath::KochCurve;
  my $path = Math::PlanePath::KochCurve->new;
  my $n_start = $path->n_start;

  my $bad = 0;
  my $report = sub {
    MyTestHelpers::diag (@_);
    $bad++;
  };

  my $count = 0;
  foreach my $y1 (-2 .. 10, 18, 30, 50, 100) {
    foreach my $y2 ($y1 .. $y1 + 10) {

      foreach my $x1 (-2 .. 10, 18, 30, 50, 100) {
        my $min;
        my $max;

        foreach my $x2 ($x1 .. $x1 + 10) {
          $count++;

          my @col = map {$path->xy_to_n($x2,$_)} $y1 .. $y2;
          @col = grep {defined} @col;
          $min = List::Util::min (grep {defined} $min, @col);
          $max = List::Util::max (grep {defined} $max, @col);
          my $want_min = (defined $min ? $min : 1);
          my $want_max = (defined $max ? $max : 0);
          ### @col
          ### rect: "$x1,$y1  $x2,$y2  expect N=$want_min..$want_max"

          foreach my $x_swap (0, 1) {
            my ($x1,$x2) = ($x_swap ? ($x1,$x2) : ($x2,$x1));
            foreach my $y_swap (0, 1) {
              my ($y1,$y2) = ($y_swap ? ($y1,$y2) : ($y2,$y1));

              my ($got_min, $got_max)
                = $path->rect_to_n_range ($x1,$y1, $x2,$y2);
              defined $got_min
                or &$report ("rect_to_n_range() got_min undef");
              defined $got_max
                or &$report ("rect_to_n_range() got_max undef");
              $got_min >= $n_start
                or &$report ("rect_to_n_range() got_min=$got_min is before n_start=$n_start");

              if (! defined $min || ! defined $max) {
                next; # outside
              }

              unless ($got_min == $want_min) {
                &$report ("rect_to_n_range() bad min $x1,$y1 $x2,$y2 got_min=$got_min want_min=$want_min".(defined $min ? '' : '[nomin]')
                         );
              }
              unless ($got_max == $want_max) {
                &$report ("rect_to_n_range() bad max $x1,$y1 $x2,$y2 got $got_max want $want_max".(defined $max ? '' : '[nomax]'));
              }
            }
          }
        }
      }
    }
  }
  MyTestHelpers::diag ("total $count rectangles");

  ok (! $bad);
}

#------------------------------------------------------------------------------
exit 0;
