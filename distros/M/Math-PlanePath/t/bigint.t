#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2015, 2018 Kevin Ryde

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

use lib 't';
use MyTestHelpers;

my $test_count = (tests => 681)[1];
plan tests => $test_count;


require Math::BigInt;
MyTestHelpers::diag ('Math::BigInt version ', Math::BigInt->VERSION);
{
  my $n = Math::BigInt->new(2) ** 256;
  my $int = int($n);
  if (! ref $int) {
    MyTestHelpers::diag ('skip due to Math::BigInt no "int()" operator');
    foreach (1 .. $test_count) {
      skip ('due to no Math::BigInt int() operator', 1, 1);
    }
    exit 0;
  }
}
{
  # as_oct() used by digit_split_lowtohigh(), and code doesn't adapt itself
  # at runtime
  my $n = Math::BigInt->new(123);
  if (! $n->can('as_oct')) {
    MyTestHelpers::diag ('skip due to Math::BigInt no "as_oct()" method');
    foreach (1 .. $test_count) {
      skip ('due to no Math::BigInt as_oct()', 1, 1);
    }
    exit 0;
  }
}

BEGIN { MyTestHelpers::nowarnings(); }

require bigint_common;
bigint_common::bigint_checks ('Math::BigInt');
exit 0;
