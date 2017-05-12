#!/usr/bin/perl -w

# Copyright 2014, 2015 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
plan tests => 15;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::HTree;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 18;
  ok ($Math::PlanePath::HTree::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::HTree->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::HTree->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::HTree->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::HTree->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::HTree->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 1);
    ok ($n_hi, 1); }  # 2^1-1
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 1);
    ok ($n_hi, 7); }  # 2^3-1
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 1);
    ok ($n_hi, 31); }  # 2^5-1
  { my ($n_lo,$n_hi) = $path->level_to_n_range(3);
    ok ($n_lo, 1);
    ok ($n_hi, 127); }  # 2^7-1
}

#------------------------------------------------------------------------------
exit 0;
