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
plan tests => 114;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::KochPeaks;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 124;
  ok ($Math::PlanePath::KochPeaks::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::KochPeaks->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::KochPeaks->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::KochPeaks->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::KochPeaks->new;
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
  my $path = Math::PlanePath::KochPeaks->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');

  my @pnames = map {$_->{'name'}} $path->parameter_info_list;
  ok (join(',',@pnames), '');
}


#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::KochPeaks->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 1);
    ok ($n_hi, 3); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 4);
    ok ($n_hi, 12); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 13);
    ok ($n_hi, 45); }

  foreach my $level (0 .. 6) {
    my ($n_lo,$n_hi) = $path->level_to_n_range($level);
    { my ($x,$y) =  $path->n_to_xy($n_lo);
      ok ($y, 0, 'level at Y=0'); }
    { my ($x,$y) =  $path->n_to_xy($n_hi);
      ok ($y, 0, 'level at Y=0'); }
  }
}

#------------------------------------------------------------------------------
# first few points

{
  my @data = ([ .5,  -1.5, -.5 ],
              [ 3.25,  1.25, -.25 ],
              [ 3.75,  -3.25, -.25 ],

              [ 1, -1,0 ],
              [ 2, 0,1 ],
              [ 3, 1,0 ],

              [ 4, -3,0 ],
              [ 5, -2,1 ],
              [ 6, -3,2 ],
              [ 7, -1,2 ],
              [ 8, 0,3 ],

              [ 9, 1,2 ],
              [ 10, 3,2 ],
              [ 11, 2,1 ],
              [ 12, 3,0 ],

              [ 13, -9,0 ],
             );
  my $path = Math::PlanePath::KochPeaks->new;
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    ok ($got_x, $want_x, "x at n=$n");
    ok ($got_y, $want_y, "y at n=$n");
  }

  foreach my $elem (@data) {
    my ($want_n, $x, $y) = @$elem;
    next unless $want_n==int($want_n);
    my $got_n = $path->xy_to_n ($x, $y);
    ok ($got_n, $want_n, "n at x=$x,y=$y");
  }

  foreach my $elem (@data) {
    my ($n, $x, $y) = @$elem;
    $n = int($n+.5);
    my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
    ok ($got_nlo <= $n, 1, "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y");
    ok ($got_nhi >= $n, 1, "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y");
  }
}


#------------------------------------------------------------------------------
# xy_to_n() distinct n

{
  my $path = Math::PlanePath::KochPeaks->new;
  my $bad = 0;
  my %seen;
  my $xlo = -5;
  my $xhi = 100;
  my $ylo = -5;
  my $yhi = 100;
  my ($nlo, $nhi) = $path->rect_to_n_range($xlo,$ylo, $xhi,$yhi);
  my $count = 0;
 OUTER: for (my $x = $xlo; $x <= $xhi; $x++) {
    for (my $y = $ylo; $y <= $yhi; $y++) {
      next unless ($x ^ $y) & 1;
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

#------------------------------------------------------------------------------
# Xlo occurances

{
  my $path = Math::PlanePath::KochPeaks->new;
  foreach my $level (0 .. 4) {
    my $n_start = $level + (2*4**$level + 1)/3;
    my $n_peak = $level + (5*4**$level + 1)/3;
    my ($x_lo,undef) = $path->n_to_xy($n_start);
    my $x_lo_count = 0;
    foreach my $n ($n_start .. $n_peak) {
      my ($x,undef) = $path->n_to_xy($n);
      if ($x == $x_lo) {
        ### found at: "level=$level x=$x n=$n"
        $x_lo_count++;
      }
    }
    ok ($x_lo_count, 2**$level);
  }
}

exit 0;
