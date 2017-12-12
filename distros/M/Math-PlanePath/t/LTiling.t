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
plan tests => 318;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Devel::Comments;

require Math::PlanePath::LTiling;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 125;
  ok ($Math::PlanePath::LTiling::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::LTiling->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::LTiling->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::LTiling->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::LTiling->new;
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
  my $path = Math::PlanePath::LTiling->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
}


#------------------------------------------------------------------------------
# centre diagonal is 0,2 digits in base 4

{
  my $path = Math::PlanePath::LTiling->new;
  for my $i (0 .. 50) {
    my $n = $path->xy_to_n ($i,$i);
    my $bits = 0;
    my $pos = 0;
    while ($n) {
      my $digit = $n % 4;
      $n = int($n/4);
      ok ($digit == 0 || $digit == 2);
      $bits |= ($digit==2) << $pos++;
    }
    ok ($bits, $i);
  }
}

#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::LTiling->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 0); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 3); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 15); }
}
{
  my $path = Math::PlanePath::LTiling->new (L_fill => 'ends');
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 1); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 7); }
}
{
  my $path = Math::PlanePath::LTiling->new (L_fill => 'all');
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 2); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 11); }
}


#------------------------------------------------------------------------------

exit 0;
