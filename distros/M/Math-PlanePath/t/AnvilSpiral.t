#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
plan tests => 31;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::AnvilSpiral;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 124;
  ok ($Math::PlanePath::AnvilSpiral::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::AnvilSpiral->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::AnvilSpiral->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::AnvilSpiral->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::AnvilSpiral->new;
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
  my $path = Math::PlanePath::AnvilSpiral->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative() instance method');
  ok ($path->y_negative, 1, 'y_negative() instance method');
  ok ($path->class_x_negative, 1, 'class_x_negative()');
  ok ($path->class_y_negative, 1, 'class_y_negative()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::AnvilSpiral->parameter_info_list;
  ok (join(',',@pnames), 'wider,n_start');
}

#------------------------------------------------------------------------------

foreach my $n_start (undef, 0, -37) {
  foreach my $wider (0, 1, 2, 3, 9, 17) {
    my $path = Math::PlanePath::AnvilSpiral->new (n_start => $n_start,
                                                  wider => $wider);
    my $bad_count = 0;

    my %seen_xy;
    foreach my $n ($path->n_start .. 500) {
      my ($x, $y) = $path->n_to_xy ($n);
      if ($seen_xy{"$x,$y"}++) {
        MyTestHelpers::diag ("wider=$wider n_to_xy($n) duplicate xy $x,$y");
        last if ++$bad_count > 10;
      }

      my $rev_n = $path->xy_to_n ($x, $y);
      if ($rev_n != $n) {
        MyTestHelpers::diag ("wider=$wider xy_to_n($x,$y) got $rev_n want $n");
        last if ++$bad_count > 10;
      }

      {
        my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, 0,0);
        if ($n_lo > $n || $n_hi < $n) {
          MyTestHelpers::diag ("wider=$wider rect_to_n_range($x,$y,0,0) got $n_lo,$n_hi but n=$n");
          last if ++$bad_count > 10;
        }
      }
      {
        my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
        if ($n_lo > $n || $n_hi < $n) {
          MyTestHelpers::diag ("wider=$wider rect_to_n_range($x,$y) got $n_lo,$n_hi but n=$n");
          last if ++$bad_count > 10;
        }
      }
    }
    ok ($bad_count, 0);
  }
}

exit 0;
