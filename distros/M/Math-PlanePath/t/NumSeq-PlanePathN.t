#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2018 Kevin Ryde

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
BEGIN { MyTestHelpers::nowarnings(); }

my $test_count = (tests => 12)[1];
plan tests => $test_count;

if (! eval { require Math::NumSeq; 1 }) {
  MyTestHelpers::diag ('skip due to Math::NumSeq not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('due to no Math::NumSeq', 1, 1);
  }
  exit 0;
}

require Math::NumSeq::PlanePathN;

#------------------------------------------------------------------------------
# characteristic()

foreach my $elem
  (['increasing',1 ], # default SquareSpiral X_axis
   ['non_decreasing', 1, planepath => 'SquareSpiral,wider=0', line_type => 'X_axis' ],

   ['increasing',        1, planepath => 'AnvilSpiral,wider=0', line_type => 'X_neg' ],
   ['increasing_from_i', 0, planepath => 'AnvilSpiral,wider=0', line_type => 'X_neg' ],

   ['increasing',        '', planepath => 'AnvilSpiral,wider=1', line_type => 'X_neg' ],
   ['increasing_from_i', 1, planepath => 'AnvilSpiral,wider=1', line_type => 'X_neg' ],

   ['increasing',        '', planepath => 'AnvilSpiral,wider=2', line_type => 'X_neg' ],
   ['increasing_from_i', 1, planepath => 'AnvilSpiral,wider=2', line_type => 'X_neg' ],

   ['increasing',        '', planepath => 'AnvilSpiral,wider=3', line_type => 'X_neg' ],
   ['increasing_from_i', 2, planepath => 'AnvilSpiral,wider=3', line_type => 'X_neg' ],

   ['increasing',        '', planepath => 'AnvilSpiral,wider=4', line_type => 'X_neg' ],
   ['increasing_from_i', 2, planepath => 'AnvilSpiral,wider=4', line_type => 'X_neg' ],
  ) {
  my ($key, $want, @parameters) = @$elem;

  my $seq = Math::NumSeq::PlanePathN->new (@parameters);
  ok ($seq->characteristic($key), $want,
      join(' ', @parameters));
}

#------------------------------------------------------------------------------
exit 0;
