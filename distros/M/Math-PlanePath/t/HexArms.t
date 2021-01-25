#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
plan tests => 126;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::HexArms;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 129;
  ok ($Math::PlanePath::HexArms::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::HexArms->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::HexArms->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::HexArms->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::HexArms->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative, arms_count

{
  my $path = Math::PlanePath::HexArms->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
  ok ($path->arms_count, 6, 'arms_count()');
}


#------------------------------------------------------------------------------
# first few points

{
  my @data = ([ 1, 0,0 ],

              [ 2, 2,0 ],
              [ 8, 3,1 ],
              [ 14, 2,2 ],

              [ 3, 1,1 ],
              [ 9, 0,2 ],
              [ 15, -2,2 ],

              [ 4, -1,1 ],
              [ 10, -3,1 ],
              [ 16, -4,0 ],

              [ 5, -2,0 ],
              [ 11, -3,-1 ],
              [ 17, -2,-2 ],

              [ 6, -1,-1 ],
              [ 12, 0,-2 ],
              [ 18, 2,-2 ],

              [ 7, 1,-1 ],
              [ 13, 3,-1 ],
              [ 19, 4,0 ],

              [ 1.75,  .75, -.75 ],
              [ 7.5,  2, -1 ],

              [ 2.25,  2.25, .25 ],

              [ 4.25,  -1.5, 1 ],

              [ 5.25,  -2.25, -.25 ],


             );
  my $path = Math::PlanePath::HexArms->new;
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    if ($got_x == 0) { $got_x = 0 }  # avoid -0
    if ($got_y == 0) { $got_y = 0 }
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
    my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
    ok ($got_nlo <= $n, 1, "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y");
    ok ($got_nhi >= $n, 1, "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y");
  }
}


#------------------------------------------------------------------------------
# xy_to_n() distinct n

# {
#   my $path = Math::PlanePath::HexArms->new;
#   my $bad = 0;
#   my %seen;
#   my $xlo = -5;
#   my $xhi = 100;
#   my $ylo = -5;
#   my $yhi = 100;
#   my ($nlo, $nhi) = $path->rect_to_n_range($xlo,$ylo, $xhi,$yhi);
#   my $count = 0;
#  OUTER: for (my $x = $xlo; $x <= $xhi; $x++) {
#     for (my $y = $ylo; $y <= $yhi; $y++) {
#       next if ($x ^ $y) & 1;
#       my $n = $path->xy_to_n ($x,$y);
#       next if ! defined $n;  # sparse
#
#       if ($seen{$n}) {
#         MyTestHelpers::diag ("x=$x,y=$y n=$n seen before at $seen{$n}");
#         last if $bad++ > 10;
#       }
#       if ($n < $nlo) {
#         MyTestHelpers::diag ("x=$x,y=$y n=$n below nlo=$nlo");
#         last OUTER if $bad++ > 10;
#       }
#       if ($n > $nhi) {
#         MyTestHelpers::diag ("x=$x,y=$y n=$n above nhi=$nhi");
#         last OUTER if $bad++ > 10;
#       }
#       $seen{$n} = "$x,$y";
#       $count++;
#     }
#   }
#   ok ($bad, 0, "xy_to_n() coverage and distinct, $count points");
# }

exit 0;
