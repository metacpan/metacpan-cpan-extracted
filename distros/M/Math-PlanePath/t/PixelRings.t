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
plan tests => 15;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::PixelRings;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 125;
  ok ($Math::PlanePath::PixelRings::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::PixelRings->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::PixelRings->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::PixelRings->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::PixelRings->new;
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
  my $path = Math::PlanePath::PixelRings->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
  ok ($path->class_x_negative, 1, 'class_x_negative()');
  ok ($path->class_y_negative, 1, 'class_y_negative()');
  ok ($path->n_frac_discontinuity, 0, 'n_frac_discontinuity()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::PixelRings->parameter_info_list;
  ok (join(',',@pnames), '');
}

#------------------------------------------------------------------------------
# xy_to_n() diagonals

{
  my $path = Math::PlanePath::PixelRings->new;
  my $bad = 0;
  for (my $i = 0; $i < 3000; $i++) {
    my $n = $path->xy_to_n ($i, $i)
      or next;
    my ($x,$y) = $path->n_to_xy ($n);
    my $got = "$x,$y";
    my $want = "$i,$i";
    if ($got ne $want) {
      MyTestHelpers::diag ("xy_to_n() wrong on diagonal $i,$i n=$n vs $x,$y");
      if ($bad++ > 10) {
        last;
      }
    }
  }
  ok ($bad, 0);
}

# {
#   my $path = Math::PlanePath::PixelRings->new;
#   my %xy_to_n;
#   ### n range: $path->rect_to_n_range (-60,-60, 60,60)
#   my ($n_lo, $n_hi) = $path->rect_to_n_range (-60,-60, 60,60);
#   foreach my $n ($n_lo .. $n_hi) {
#     my ($x,$y) = $path->n_to_xy($n);
#     my $key = "$x,$y";
#     if ($xy_to_n{$key}) {
#       die "Oops, n_to_xy repeat $x,$y: was $xy_to_n{$key} now $n too";
#     }
#     $xy_to_n{$key} = $n;
#     ### n_to_xy gives: "$x,$y -> $n"
#   }
#   ### total: scalar(%xy_to_n)
#   foreach my $x (0 .. 60, -60 .. -1) {
#     foreach my $y (0 .. 60, -60 .. -1) {
#       ok ($path->xy_to_n($x,$y), $xy_to_n{"$x,$y"},
#           "xy_to_n($x,$y)");
#     }
#   }
# }

exit 0;
