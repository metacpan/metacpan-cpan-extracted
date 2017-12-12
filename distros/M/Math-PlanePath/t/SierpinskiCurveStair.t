#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
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
plan tests => 53;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::SierpinskiCurveStair;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 125;
  ok ($Math::PlanePath::SierpinskiCurveStair::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::SierpinskiCurveStair->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::SierpinskiCurveStair->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::SierpinskiCurveStair->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::SierpinskiCurveStair->new;
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
  my $path = Math::PlanePath::SierpinskiCurveStair->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative ? 1 : 0, 0, 'x_negative()');
  ok ($path->y_negative ? 1 : 0, 0, 'y_negative()');

  my @pnames = map {$_->{'name'}}
    Math::PlanePath::SierpinskiCurveStair->parameter_info_list;
  ok (join(',',@pnames), 'diagonal_length,arms');
}
{
  my $path = Math::PlanePath::SierpinskiCurveStair->new (arms => 2);
  ok ($path->x_negative ? 1 : 0, 0, 'x_negative()');
  ok ($path->y_negative ? 1 : 0, 0, 'y_negative()');
}
{
  my $path = Math::PlanePath::SierpinskiCurveStair->new (arms => 3);
  ok ($path->x_negative ? 1 : 0, 1, 'x_negative()');
  ok ($path->y_negative ? 1 : 0, 0, 'y_negative()');
}
{
  my $path = Math::PlanePath::SierpinskiCurveStair->new (arms => 4);
  ok ($path->x_negative ? 1 : 0, 1, 'x_negative()');
  ok ($path->y_negative ? 1 : 0, 0, 'y_negative()');
}
{
  my $path = Math::PlanePath::SierpinskiCurveStair->new (arms => 5);
  ok ($path->x_negative ? 1 : 0, 1, 'x_negative()');
  ok ($path->y_negative ? 1 : 0, 1, 'y_negative()');
}
{
  my $path = Math::PlanePath::SierpinskiCurveStair->new (arms => 8);
  ok ($path->x_negative ? 1 : 0, 1, 'x_negative()');
  ok ($path->y_negative ? 1 : 0, 1, 'y_negative()');
}

#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::SierpinskiCurveStair->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 0);
  }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 5);
    my ($x,$y) =  $path->n_to_xy($n_hi);
    ok ($x, 4);
  }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 25);
    my ($x,$y) =  $path->n_to_xy($n_hi);
    ok ($x, 10);
  }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(3);
    ok ($n_lo, 0);
    ok ($n_hi, 105);
    my ($x,$y) =  $path->n_to_xy($n_hi);
    ok ($x, 22);
  }
  foreach my $level (0 .. 5) {
    my ($n_lo,$n_hi) = $path->level_to_n_range($level);
    { my ($x,$y) =  $path->n_to_xy($n_hi);
      ok ($y, 0, 'level at Y=0'); }
    if ($n_hi > 0) {
      { my ($x,$y) =  $path->n_to_xy($n_hi - 1);
        ok ($y, 0, 'before level at Y=0 too'); }
      { my ($x,$y) =  $path->n_to_xy($n_hi + 1);
        ok ($y, 1, 'after level at Y=1'); }
    }
  }
}
{
  my $path = Math::PlanePath::SierpinskiCurveStair->new (arms => 8);
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 7); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 47); }
}

#------------------------------------------------------------------------------
# xy_to_n() distinct n

{
  my $bad = 0;
  my $count = 0;
  foreach my $arms (1 .. 8) {
    foreach my $diagonal_length (1 .. 4) {
      my $xlo = -5;
      my $xhi = 8*($diagonal_length+1);
      my $ylo = -5;
      my $yhi = 8*($diagonal_length+1);
      my $path = Math::PlanePath::SierpinskiCurveStair->new
        (arms => $arms,
         diagonal_length => $diagonal_length);
      my ($nlo, $nhi) = $path->rect_to_n_range($xlo,$ylo, $xhi,$yhi);
      my %seen;
    OUTER: for (my $x = $xlo; $x <= $xhi; $x++) {
        for (my $y = $ylo; $y <= $yhi; $y++) {
          next if ($x ^ $y) & 1;
          my $n = $path->xy_to_n ($x,$y);
          next if ! defined $n;  # sparse

          if ($seen{$n}) {
            MyTestHelpers::diag ("dl=$diagonal_length arms=$arms  x=$x,y=$y n=$n seen before at $seen{$n}");
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
    }
  }
  ok ($bad, 0, "xy_to_n() coverage and distinct, $count points");
}


#------------------------------------------------------------------------------
exit 0;
