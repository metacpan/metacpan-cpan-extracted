#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
plan tests => 2940;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::PeanoCurve;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 128;
  ok ($Math::PlanePath::PeanoCurve::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::PeanoCurve->VERSION, $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::PeanoCurve->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::PeanoCurve->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::PeanoCurve->new;
  ok ($path->VERSION, $want_version, 'VERSION object method');

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
  my $path = Math::PlanePath::PeanoCurve->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative() instance method');
  ok ($path->y_negative, 0, 'y_negative() instance method');
}

#------------------------------------------------------------------------------
# X=Y diagonal is ternary digits duplicated
# A163343, and A163344 sans factor 4

#                    0 1 2     
my @n_on_diagonal = (0,4,8);  # 4*digit
sub n_on_diagonal {
  my ($n) = @_;
  my @n = Math::PlanePath::Base::Digits::digit_split_lowtohigh($n,3);
  my $rev = 0;
  foreach my $digit (reverse @n) {  # high to low, mutate array
    $rev ^= ($digit==1);
    if ($rev) { $digit = 2-$digit; }
    $digit = $n_on_diagonal[$digit];
  }
  return Math::PlanePath::Base::Digits::digit_join_lowtohigh (\@n,9);
}
{
  # d(3n)   = 9 d(n) + (8 if n odd)
  # d(3n+1) = 9 d(n) + 4
  # d(3n+2) = 9 d(n) + (8 if n even)
  my $path = Math::PlanePath::PeanoCurve->new;
  foreach my $i (0 .. 3**6) {
    ok (n_on_diagonal($i), $path->xy_to_n($i,$i),
        'N on X=Y diagonal');
    ok (n_on_diagonal(3*$i),   9*n_on_diagonal($i) + ($i%2==1 ? 8 : 0),
        'N on X=Y diagonal, recurrence 3i');
    ok (n_on_diagonal(3*$i+1), 9*n_on_diagonal($i) + 4,
        'N on X=Y diagonal, recurrence 3i+1');
    ok (n_on_diagonal(3*$i+2), 9*n_on_diagonal($i) + ($i%2==0 ? 8 : 0),
        'N on X=Y diagonal, recurrence 3i+2');
  }
}

#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::PeanoCurve->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 0); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 8); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 80); }
}
{
  my $path = Math::PlanePath::PeanoCurve->new (radix => 5);
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 0); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 24); }
}

#------------------------------------------------------------------------------

exit 0;
