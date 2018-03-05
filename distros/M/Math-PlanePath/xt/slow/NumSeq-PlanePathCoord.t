#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2018 Kevin Ryde

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
use Data::Float 'pos_infinity';
use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::Base::Generic
  'is_infinite';

# uncomment this to run the ### lines
# use Smart::Comments '###';


my $test_count = (tests => 1045)[1];
plan tests => $test_count;

if (! eval { require Math::NumSeq; 1 }) {
  MyTestHelpers::diag ('skip due to Math::NumSeq not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('due to no Math::NumSeq', 1, 1);
  }
  exit 0;
}

require Math::NumSeq::PlanePathCoord;


sub want_planepath {
  my ($planepath) = @_;
  # return 0 unless $planepath =~ /HTree/;
  # return 0 unless $planepath =~ /DiagonalRationals/;
  # return 0 unless $planepath =~ /FactorRationals/;
  # return 0 unless $planepath =~ /MultipleRings/;
  # return 0 unless $planepath =~ /Anvil/;
  return 1;
}
sub want_coordinate {
  my ($type) = @_;
  # return 0 unless $type =~ /sumabs|absdiff/i;
  # return 0 unless $type =~ /d[XY]/;
  # return 0 unless $type =~ /^dAbsDiff/;
  #  return 0 unless $type =~ /TR/;
  #  return 0 unless $type =~ /RSquared|Radius/;
  # return 0 unless $type =~ /Left|Right|LSR|SLR|SRL/;
  #  return 0 unless $type =~ /Dir4|Dir6/;
  # return 0 unless $type =~ /LeafDistance/;
  #   return 0 unless $type =~ /Min|Max/;
  # return 0 unless $type =~ /dSum|dDiffXY|Absd|d[XY]/;
  # return 0 unless $type =~ /^(X|Y|Sum|DiffXY|dX|dY|AbsdX|AbsdY|dSum|dDiffXY|Dir4)$/;
  # return 0 unless $type =~ /^(X|Y|Sum|DiffXY|DiffYX)$/;
   return 0 unless $type =~ /^(Left|Right|Straight|S..|.S.)$/;
  return 1;
}


#------------------------------------------------------------------------------
# characteristic()

foreach my $elem
  (['increasing',0 ], # default SquareSpiral X not monotonic
   ['non_decreasing', 1, planepath => 'Hypot', coordinate_type => 'Radius' ],
   ['non_decreasing', 1, planepath => 'Hypot', coordinate_type => 'Radius' ],
   ['non_decreasing', 1, planepath => 'HypotOctant', coordinate_type => 'Radius' ],
   ['non_decreasing', 1, planepath => 'HypotOctant', coordinate_type => 'RSquared' ],

   ['smaller', 1, planepath => 'SquareSpiral', coordinate_type => 'X' ],
   ['smaller', 1, planepath => 'SquareSpiral', coordinate_type => 'RSquared' ],

   ['smaller', 0, planepath => 'MultipleRings,step=0', coordinate_type => 'RSquared' ],
   ['smaller', 0, planepath => 'MultipleRings,step=1', coordinate_type => 'RSquared' ],
   ['smaller', 1, planepath => 'MultipleRings,step=2', coordinate_type => 'RSquared' ],

   ['increasing', 1, planepath => 'TheodorusSpiral', coordinate_type => 'Radius' ],
   ['increasing', 1, planepath => 'TheodorusSpiral', coordinate_type => 'RSquared' ],
   ['non_decreasing', 1, planepath => 'TheodorusSpiral', coordinate_type => 'Radius' ],
   ['non_decreasing', 1, planepath => 'TheodorusSpiral', coordinate_type => 'RSquared' ],
   ['smaller', 1, planepath => 'TheodorusSpiral', coordinate_type => 'Radius' ],
   ['smaller', 0, planepath => 'TheodorusSpiral', coordinate_type => 'RSquared' ],

   ['increasing', 1, planepath => 'VogelFloret', coordinate_type => 'Radius' ],
   ['increasing', 1, planepath => 'VogelFloret', coordinate_type => 'RSquared' ],
   ['non_decreasing', 1, planepath => 'VogelFloret', coordinate_type => 'Radius' ],
   ['non_decreasing', 1, planepath => 'VogelFloret', coordinate_type => 'RSquared' ],
   ['smaller', 1, planepath => 'VogelFloret', coordinate_type => 'Radius' ],
   ['smaller', 0, planepath => 'VogelFloret', coordinate_type => 'RSquared' ],

   ['increasing', 1, planepath => 'SacksSpiral', coordinate_type => 'Radius' ],
   ['increasing', 1, planepath => 'SacksSpiral', coordinate_type => 'RSquared' ],
   ['non_decreasing', 1, planepath => 'SacksSpiral', coordinate_type => 'Radius' ],
   ['non_decreasing', 1, planepath => 'SacksSpiral', coordinate_type => 'RSquared' ],
   ['smaller', 1, planepath => 'SacksSpiral', coordinate_type => 'Radius' ],
   ['smaller', 0, planepath => 'SacksSpiral', coordinate_type => 'RSquared' ],

  ) {
  my ($key, $want, @parameters) = @$elem;

  my $seq = Math::NumSeq::PlanePathCoord->new (@parameters);
  ok ($seq->characteristic($key) ? 1 : 0, $want,
      "characteristic($key) on ".join(', ',@parameters));
}


#------------------------------------------------------------------------------
# values_min(), values_max()

foreach my $elem
  ([undef,undef, planepath => 'SquareSpiral' ], # default coordinate_type=>X
   [0,undef, planepath => 'SquareSpiral', coordinate_type => 'Radius' ],
   [0,undef, planepath => 'SquareSpiral', coordinate_type => 'RSquared' ],

   [0,undef, planepath => 'HilbertCurve', coordinate_type => 'X' ],
   [0,undef, planepath => 'HilbertCurve', coordinate_type => 'Y' ],
   [0,undef, planepath => 'HilbertCurve', coordinate_type => 'Sum' ],
   [0,undef, planepath => 'HilbertCurve', coordinate_type => 'Product' ],

   [undef,undef, planepath => 'CellularRule54', coordinate_type => 'X' ],
   [0,undef,     planepath => 'CellularRule54', coordinate_type => 'Y' ],
   [0,undef,     planepath => 'CellularRule54', coordinate_type => 'Sum' ],
   [undef,undef, planepath => 'CellularRule54', coordinate_type => 'Product' ],
   [0,undef,     planepath => 'CellularRule54', coordinate_type => 'Radius' ],
   [0,undef,     planepath => 'CellularRule54', coordinate_type => 'RSquared' ],
   [undef,0,     planepath => 'CellularRule54', coordinate_type => 'DiffXY' ],
   [0,undef,     planepath => 'CellularRule54', coordinate_type => 'DiffYX' ],
   [0,undef,     planepath => 'CellularRule54', coordinate_type => 'AbsDiff' ],

   [undef,undef, planepath => 'CellularRule190', coordinate_type => 'X' ],
   [0,undef,     planepath => 'CellularRule190', coordinate_type => 'Y' ],
   [0,undef,     planepath => 'CellularRule190', coordinate_type => 'Sum' ],
   [undef,undef, planepath => 'CellularRule190', coordinate_type => 'Product' ],
   [0,undef,   planepath => 'CellularRule190', coordinate_type => 'Radius' ],
   [0,undef,   planepath => 'CellularRule190', coordinate_type => 'RSquared' ],

   [undef,undef, planepath => 'UlamWarburton', coordinate_type => 'X' ],
   [undef,undef, planepath => 'UlamWarburton', coordinate_type => 'Y' ],
   [undef,undef, planepath => 'UlamWarburton', coordinate_type => 'Sum' ],
   [undef,undef, planepath => 'UlamWarburton', coordinate_type => 'Product' ],
   [0,undef, planepath => 'UlamWarburton', coordinate_type => 'Radius' ],
   [0,undef, planepath => 'UlamWarburton', coordinate_type => 'RSquared' ],

   [0,undef, planepath => 'UlamWarburtonQuarter', coordinate_type => 'X' ],
   [0,undef, planepath => 'UlamWarburtonQuarter', coordinate_type => 'Y' ],
   [0,undef, planepath => 'UlamWarburtonQuarter', coordinate_type => 'Sum' ],
   [0,undef, planepath => 'UlamWarburtonQuarter', coordinate_type => 'Product' ],
   [0,undef, planepath => 'UlamWarburtonQuarter', coordinate_type => 'Radius' ],
   [0,undef, planepath => 'UlamWarburtonQuarter', coordinate_type => 'RSquared' ],


   [3,undef, planepath => 'PythagoreanTree', coordinate_type => 'X' ],
   [4,undef, planepath => 'PythagoreanTree', coordinate_type => 'Y' ],
   [7,undef, planepath => 'PythagoreanTree', coordinate_type => 'Sum' ],
   [3*4,undef, planepath => 'PythagoreanTree', coordinate_type => 'Product' ],
   [5,undef, planepath => 'PythagoreanTree', coordinate_type => 'Radius' ],
   [25,undef, planepath => 'PythagoreanTree', coordinate_type => 'RSquared' ],
   [undef,undef, planepath => 'PythagoreanTree', coordinate_type => 'DiffXY' ],
   [undef,undef, planepath => 'PythagoreanTree', coordinate_type => 'DiffYX' ],
   [1,undef, planepath => 'PythagoreanTree', coordinate_type => 'AbsDiff' ],

   [2,undef, planepath => 'PythagoreanTree,coordinates=PQ', coordinate_type => 'X' ],
   [1,undef, planepath => 'PythagoreanTree,coordinates=PQ', coordinate_type => 'Y' ],
   [3,undef, planepath => 'PythagoreanTree,coordinates=PQ', coordinate_type => 'Sum' ],
   [2,undef, planepath => 'PythagoreanTree,coordinates=PQ', coordinate_type => 'Product' ],
   #[sqrt(5),undef, planepath => 'PythagoreanTree,coordinates=PQ', coordinate_type => 'Radius' ],
   [5,undef, planepath => 'PythagoreanTree,coordinates=PQ', coordinate_type => 'RSquared' ],
   [1,undef, planepath => 'PythagoreanTree,coordinates=PQ', coordinate_type => 'DiffXY' ],
   [undef,-1, planepath => 'PythagoreanTree,coordinates=PQ', coordinate_type => 'DiffYX' ],
   [1,undef, planepath => 'PythagoreanTree,coordinates=PQ', coordinate_type => 'AbsDiff' ],


   [0,undef, planepath => 'HypotOctant', coordinate_type => 'X' ],
   [0,undef, planepath => 'HypotOctant', coordinate_type => 'Y' ],
   [0,undef, planepath => 'HypotOctant', coordinate_type => 'Sum' ],
   [0,undef, planepath => 'HypotOctant', coordinate_type => 'Product' ],
   [0,undef, planepath => 'HypotOctant', coordinate_type => 'Radius' ],
   [0,undef, planepath => 'HypotOctant', coordinate_type => 'RSquared' ],
   [0,undef, planepath => 'HypotOctant', coordinate_type => 'DiffXY' ],
   [undef,0, planepath => 'HypotOctant', coordinate_type => 'DiffYX' ],
   [0,undef, planepath => 'HypotOctant', coordinate_type => 'AbsDiff' ],


   [2,undef, planepath => 'DivisibleColumns,divisor_type=proper', coordinate_type => 'X' ],
   [1,undef, planepath => 'DivisibleColumns,divisor_type=proper', coordinate_type => 'Y' ],
   [3,undef, planepath => 'DivisibleColumns,divisor_type=proper', coordinate_type => 'Sum' ],
   [2,undef, planepath => 'DivisibleColumns,divisor_type=proper', coordinate_type => 'Product' ],
   # [sqrt(5),undef, planepath => 'DivisibleColumns,divisor_type=proper', coordinate_type => 'Radius' ],
   [5,undef, planepath => 'DivisibleColumns,divisor_type=proper', coordinate_type => 'RSquared' ],
   [1,undef, planepath => 'DivisibleColumns,divisor_type=proper', coordinate_type => 'DiffXY' ],
   [undef,-1, planepath => 'DivisibleColumns,divisor_type=proper', coordinate_type => 'DiffYX' ],
   [1,undef, planepath => 'DivisibleColumns,divisor_type=proper', coordinate_type => 'AbsDiff' ],

   [1,undef, planepath => 'DivisibleColumns', coordinate_type => 'X' ],
   [1,undef, planepath => 'DivisibleColumns', coordinate_type => 'Y' ],
   [2,undef, planepath => 'DivisibleColumns', coordinate_type => 'Sum' ],
   [1,undef, planepath => 'DivisibleColumns', coordinate_type => 'Product' ],
   # [sqrt(2),undef, planepath => 'DivisibleColumns', coordinate_type => 'Radius' ],
   [2,undef, planepath => 'DivisibleColumns', coordinate_type => 'RSquared' ],
   [0,undef, planepath => 'DivisibleColumns', coordinate_type => 'DiffXY' ],
   [undef,0, planepath => 'DivisibleColumns', coordinate_type => 'DiffYX' ],
   [0,undef, planepath => 'DivisibleColumns', coordinate_type => 'AbsDiff' ],


   [1,undef, planepath => 'CoprimeColumns', coordinate_type => 'X' ],
   [1,undef, planepath => 'CoprimeColumns', coordinate_type => 'Y' ],
   [2,undef, planepath => 'CoprimeColumns', coordinate_type => 'Sum' ],
   [1,undef, planepath => 'CoprimeColumns', coordinate_type => 'Product' ],
   # [sqrt(2),undef, planepath => 'CoprimeColumns', coordinate_type => 'Radius' ],
   [2,undef, planepath => 'CoprimeColumns', coordinate_type => 'RSquared' ],
   [0,undef, planepath => 'CoprimeColumns', coordinate_type => 'DiffXY' ],
   [undef,0, planepath => 'CoprimeColumns', coordinate_type => 'DiffYX' ],
   [0,undef, planepath => 'CoprimeColumns', coordinate_type => 'AbsDiff' ],

   [1,undef, planepath => 'RationalsTree', coordinate_type => 'X' ],
   [1,undef, planepath => 'RationalsTree', coordinate_type => 'Y' ],
   # X>=1 and Y>=1 always so Sum>=2
   [2,undef, planepath => 'RationalsTree', coordinate_type => 'Sum' ],
   [1,undef, planepath => 'RationalsTree', coordinate_type => 'Product' ],
   # [sqrt(2),undef, planepath => 'RationalsTree', coordinate_type => 'Radius' ],
   [2,undef, planepath => 'RationalsTree', coordinate_type => 'RSquared' ],
   # whole first quadrant so diff positive and negative
   [undef,undef, planepath => 'RationalsTree', coordinate_type => 'DiffXY' ],
   [undef,undef, planepath => 'RationalsTree', coordinate_type => 'DiffYX' ],
   [0,undef,     planepath => 'RationalsTree', coordinate_type => 'AbsDiff' ],

   [0,undef, planepath => 'QuadricCurve', coordinate_type => 'X' ],
   [undef,undef, planepath => 'QuadricCurve', coordinate_type => 'Y' ],
   [0,undef, planepath => 'QuadricCurve', coordinate_type => 'Sum' ],
   [undef,undef, planepath => 'QuadricCurve', coordinate_type => 'Product' ],
   [0,undef, planepath => 'QuadricCurve', coordinate_type => 'Radius' ],
   [0,undef, planepath => 'QuadricCurve', coordinate_type => 'RSquared' ],
   [0,undef, planepath => 'QuadricCurve', coordinate_type => 'DiffXY' ],
   [undef,0, planepath => 'QuadricCurve', coordinate_type => 'DiffYX' ],
   [0,undef, planepath => 'QuadricCurve', coordinate_type => 'AbsDiff' ],

   [0,5,      planepath => 'Rows,width=6', coordinate_type => 'X' ],
   [0,undef,  planepath => 'Rows,width=6', coordinate_type => 'Y' ],
   [0,undef,  planepath => 'Rows,width=6', coordinate_type => 'Sum' ],
   [0,undef,  planepath => 'Rows,width=6', coordinate_type => 'Product' ],
   [0,undef,  planepath => 'Rows,width=6', coordinate_type => 'Radius' ],
   [0,undef,  planepath => 'Rows,width=6', coordinate_type => 'RSquared' ],
   [undef,5,  planepath => 'Rows,width=6', coordinate_type => 'DiffXY' ],
   [-5,undef, planepath => 'Rows,width=6', coordinate_type => 'DiffYX' ],
   [0,undef,  planepath => 'Rows,width=6', coordinate_type => 'AbsDiff' ],

   [0,undef,  planepath => 'Columns,height=6', coordinate_type => 'X' ],
   [0,5,      planepath => 'Columns,height=6', coordinate_type => 'Y' ],
   [0,undef,  planepath => 'Columns,height=6', coordinate_type => 'Sum' ],
   [0,undef,  planepath => 'Columns,height=6', coordinate_type => 'Product' ],
   [0,undef,  planepath => 'Columns,height=6', coordinate_type => 'Radius' ],
   [0,undef,  planepath => 'Columns,height=6', coordinate_type => 'RSquared' ],
   [-5,undef, planepath => 'Columns,height=6', coordinate_type => 'DiffXY' ],
   [undef,5,  planepath => 'Columns,height=6', coordinate_type => 'DiffYX' ],
   [0,undef,  planepath => 'Columns,height=6', coordinate_type => 'AbsDiff' ],

   # step=0 vertical on Y axis only
   [0,0,     planepath=>'PyramidRows,step=0', coordinate_type => 'X' ],
   [0,undef, planepath=>'PyramidRows,step=0', coordinate_type => 'Y' ],
   [0,undef, planepath=>'PyramidRows,step=0', coordinate_type => 'Sum' ],
   [0,0,     planepath=>'PyramidRows,step=0', coordinate_type => 'Product' ],
   [0,undef, planepath=>'PyramidRows,step=0', coordinate_type => 'Radius' ],
   [0,undef, planepath=>'PyramidRows,step=0', coordinate_type => 'RSquared' ],
   [undef,0, planepath=>'PyramidRows,step=0', coordinate_type => 'DiffXY' ],
   [0,undef, planepath=>'PyramidRows,step=0', coordinate_type => 'DiffYX' ],
   [0,undef, planepath=>'PyramidRows,step=0', coordinate_type => 'AbsDiff' ],

   [0,undef, planepath=>'PyramidRows,step=1', coordinate_type => 'X' ],
   [0,undef, planepath=>'PyramidRows,step=1', coordinate_type => 'Y' ],
   [0,undef, planepath=>'PyramidRows,step=1', coordinate_type => 'Sum' ],
   [0,undef, planepath=>'PyramidRows,step=1', coordinate_type => 'Product' ],
   [0,undef, planepath=>'PyramidRows,step=1', coordinate_type => 'Radius' ],
   [0,undef, planepath=>'PyramidRows,step=1', coordinate_type => 'RSquared' ],
   [undef,0, planepath=>'PyramidRows,step=1', coordinate_type => 'DiffXY' ],
   [0,undef, planepath=>'PyramidRows,step=1', coordinate_type => 'DiffYX' ],
   [0,undef, planepath=>'PyramidRows,step=1', coordinate_type => 'AbsDiff' ],

   [undef,undef, planepath=>'PyramidRows,step=2', coordinate_type=>'X' ],
   [0,undef,     planepath=>'PyramidRows,step=2', coordinate_type=>'Y' ],
   [0,undef,     planepath=>'PyramidRows,step=2', coordinate_type=>'Sum' ],
   [undef,undef, planepath=>'PyramidRows,step=2', coordinate_type=>'Product' ],
   [0,undef,     planepath=>'PyramidRows,step=2', coordinate_type=>'Radius' ],
   [0,undef,     planepath=>'PyramidRows,step=2', coordinate_type=>'RSquared'],
   [undef,0,     planepath=>'PyramidRows,step=2', coordinate_type=>'DiffXY' ],
   [0,undef,     planepath=>'PyramidRows,step=2', coordinate_type=>'DiffYX' ],
   [0,undef,     planepath=>'PyramidRows,step=2', coordinate_type=>'AbsDiff' ],

   [undef,undef, planepath => 'PyramidRows,step=3', coordinate_type => 'X' ],
   [0,undef, planepath => 'PyramidRows,step=3', coordinate_type => 'Y' ],
   [0,undef, planepath => 'PyramidRows,step=3', coordinate_type => 'Sum' ],
   [undef,undef, planepath => 'PyramidRows,step=3', coordinate_type => 'Product' ],
   [0,undef, planepath => 'PyramidRows,step=3', coordinate_type => 'Radius' ],
   [0,undef, planepath => 'PyramidRows,step=3', coordinate_type => 'RSquared' ],
   [undef,undef, planepath => 'PyramidRows,step=3', coordinate_type => 'DiffXY' ],
   [undef,undef, planepath => 'PyramidRows,step=3', coordinate_type => 'DiffYX' ],
   [0,undef, planepath => 'PyramidRows,step=3', coordinate_type => 'AbsDiff' ],

   # Y <= X-1, so X-Y >= 1
   #              Y-X <= -1
   [1,undef, planepath => 'SierpinskiCurve', coordinate_type => 'DiffXY' ],
   [undef,-1, planepath => 'SierpinskiCurve', coordinate_type => 'DiffYX' ],
   [1,undef, planepath => 'SierpinskiCurve', coordinate_type => 'AbsDiff' ],

   [0,undef, planepath => 'HIndexing', coordinate_type => 'X' ],
   [0,undef, planepath => 'HIndexing', coordinate_type => 'Y' ],
   [0,undef, planepath => 'HIndexing', coordinate_type => 'Sum' ],
   [0,undef, planepath => 'HIndexing', coordinate_type => 'Product' ],
   [0,undef, planepath => 'HIndexing', coordinate_type => 'Radius' ],
   [0,undef, planepath => 'HIndexing', coordinate_type => 'RSquared' ],
   [undef,0, planepath => 'HIndexing', coordinate_type => 'DiffXY' ],
   [0,undef, planepath => 'HIndexing', coordinate_type => 'DiffYX' ],
   [0,undef, planepath => 'HIndexing', coordinate_type => 'AbsDiff' ],

   # right line
   [0,undef, planepath=>'CellularRule,rule=16', coordinate_type=>'X' ],
   [0,undef, planepath=>'CellularRule,rule=16', coordinate_type=>'Y' ],
   [0,undef, planepath=>'CellularRule,rule=16', coordinate_type=>'Sum' ],
   [0,undef, planepath=>'CellularRule,rule=16', coordinate_type=>'Product' ],
   [0,undef, planepath=>'CellularRule,rule=16', coordinate_type=>'Radius' ],
   [0,undef, planepath=>'CellularRule,rule=16', coordinate_type=>'RSquared' ],
   [0,0,     planepath=>'CellularRule,rule=16', coordinate_type=>'DiffXY' ],
   [0,0,     planepath=>'CellularRule,rule=16', coordinate_type=>'DiffYX' ],
   [0,0,     planepath=>'CellularRule,rule=16', coordinate_type=>'AbsDiff' ],

   # centre line Y axis only
   [0,0,     planepath=>'CellularRule,rule=4', coordinate_type => 'X' ],
   [0,undef, planepath=>'CellularRule,rule=4', coordinate_type => 'Y' ],
   [0,undef, planepath=>'CellularRule,rule=4', coordinate_type => 'Sum' ],
   [0,0,     planepath=>'CellularRule,rule=4', coordinate_type => 'Product' ],
   [0,undef, planepath=>'CellularRule,rule=4', coordinate_type => 'Radius' ],
   [0,undef, planepath=>'CellularRule,rule=4', coordinate_type => 'RSquared' ],
   [undef,0, planepath=>'CellularRule,rule=4', coordinate_type => 'DiffXY' ],
   [0,undef, planepath=>'CellularRule,rule=4', coordinate_type => 'DiffYX' ],
   [0,undef, planepath=>'CellularRule,rule=4', coordinate_type => 'AbsDiff' ],

   # left line
   [undef,0, planepath=>'CellularRule,rule=2', coordinate_type=>'X' ],
   [0,undef, planepath=>'CellularRule,rule=2', coordinate_type=>'Y' ],
   [0,0,     planepath=>'CellularRule,rule=2', coordinate_type=>'Sum' ],
   [undef,0, planepath=>'CellularRule,rule=2', coordinate_type=>'Product' ],
   [0,undef, planepath=>'CellularRule,rule=2', coordinate_type=>'Radius' ],
   [0,undef, planepath=>'CellularRule,rule=2', coordinate_type=>'RSquared' ],
   [undef,0, planepath=>'CellularRule,rule=2', coordinate_type=>'DiffXY' ],
   [0,undef, planepath=>'CellularRule,rule=2', coordinate_type=>'DiffYX' ],
   [0,undef, planepath=>'CellularRule,rule=2', coordinate_type=>'AbsDiff' ],

   # left solid
   [undef,0, planepath=>'CellularRule,rule=206', coordinate_type=>'X' ],
   [0,undef, planepath=>'CellularRule,rule=206', coordinate_type=>'Y' ],
   [0,undef, planepath=>'CellularRule,rule=206', coordinate_type=>'Sum' ],
   [undef,0, planepath=>'CellularRule,rule=206', coordinate_type=>'Product' ],
   [0,undef, planepath=>'CellularRule,rule=206', coordinate_type=>'Radius' ],
   [0,undef, planepath=>'CellularRule,rule=206', coordinate_type=>'RSquared' ],
   [undef,0, planepath=>'CellularRule,rule=206', coordinate_type=>'DiffXY' ],
   [0,undef, planepath=>'CellularRule,rule=206', coordinate_type=>'DiffYX' ],
   [0,undef, planepath=>'CellularRule,rule=206', coordinate_type=>'AbsDiff' ],

   # odd solid
   [undef,undef, planepath=>'CellularRule,rule=50',coordinate_type=>'X' ],
   [0,undef,     planepath=>'CellularRule,rule=50',coordinate_type=>'Y' ],
   [0,undef,     planepath=>'CellularRule,rule=50',coordinate_type=>'Sum' ],
   [undef,undef, planepath=>'CellularRule,rule=50',coordinate_type=>'Product'],
   [0,undef,    planepath=>'CellularRule,rule=50',coordinate_type=>'Radius' ],
   [0,undef,    planepath=>'CellularRule,rule=50',coordinate_type=>'RSquared'],
   [undef,0,    planepath=>'CellularRule,rule=50',coordinate_type=>'DiffXY' ],
   [0,undef,    planepath=>'CellularRule,rule=50',coordinate_type=>'DiffYX' ],
   [0,undef,    planepath=>'CellularRule,rule=50',coordinate_type=>'AbsDiff' ],
  ) {
  my ($want_min,$want_max, @parameters) = @$elem;
  ### @parameters
  ### $want_min
  ### $want_max

  my $seq = Math::NumSeq::PlanePathCoord->new (@parameters);
  ok ($seq->values_min, $want_min,
      "values_min() ".join(',',@parameters));
  ok ($seq->values_max, $want_max,
      "values_max() ".join(',',@parameters));
}


#------------------------------------------------------------------------------
# values_min(), values_max() by running values

my @modules = (
               # 'FourReplicate',

               # module list begin

               'AlternateTerdragon',
               'AlternateTerdragon,arms=2',
               'AlternateTerdragon,arms=3',
               'AlternateTerdragon,arms=4',
               'AlternateTerdragon,arms=5',
               'AlternateTerdragon,arms=6',

               'VogelFloret',
               'VogelFloret,rotation_type=sqrt2',
               'VogelFloret,rotation_type=sqrt3',
               'VogelFloret,rotation_type=sqrt5',
               'SacksSpiral',
               'TheodorusSpiral',
               'ArchimedeanChords',

               'MultipleRings,step=0',
               'MultipleRings,ring_shape=polygon,step=0',
               'MultipleRings,step=1',
               'MultipleRings,ring_shape=polygon,step=1',
               'MultipleRings,step=2',
               'MultipleRings,ring_shape=polygon,step=2',
               'MultipleRings,step=3',
               'MultipleRings,step=5',
               'MultipleRings,step=6',
               'MultipleRings,step=7',
               'MultipleRings,step=8',
               'MultipleRings,step=37',

               'MultipleRings,ring_shape=polygon,step=3',
               'MultipleRings,ring_shape=polygon,step=4',
               'MultipleRings,ring_shape=polygon,step=5',
               'MultipleRings,ring_shape=polygon,step=6',
               'MultipleRings,ring_shape=polygon,step=7',
               'MultipleRings,ring_shape=polygon,step=8',
               'MultipleRings,ring_shape=polygon,step=9',
               'MultipleRings,ring_shape=polygon,step=10',
               'MultipleRings,ring_shape=polygon,step=11',
               'MultipleRings,ring_shape=polygon,step=12',
               'MultipleRings,ring_shape=polygon,step=13',
               'MultipleRings,ring_shape=polygon,step=14',
               'MultipleRings,ring_shape=polygon,step=15',
               'MultipleRings,ring_shape=polygon,step=16',
               'MultipleRings,ring_shape=polygon,step=17',
               'MultipleRings,ring_shape=polygon,step=18',
               'MultipleRings,ring_shape=polygon,step=37',

               'SquareSpiral',
               'SquareSpiral,wider=1',
               'SquareSpiral,wider=2',
               'SquareSpiral,wider=3',
               'SquareSpiral,wider=4',
               'SquareSpiral,wider=5',
               'SquareSpiral,wider=6',
               'SquareSpiral,wider=37',
               'SquareSpiral,n_start=37',
               'SquareSpiral,n_start=37,wider=1',
               'SquareSpiral,n_start=37,wider=2',
               'SquareSpiral,n_start=37,wider=3',
               'SquareSpiral,n_start=37,wider=4',
               'SquareSpiral,n_start=37,wider=5',
               'SquareSpiral,n_start=37,wider=6',
               'SquareSpiral,n_start=37,wider=37',

               'GreekKeySpiral',
               'GreekKeySpiral,turns=0',
               'GreekKeySpiral,turns=1',
               'GreekKeySpiral,turns=3',
               'GreekKeySpiral,turns=4',
               'GreekKeySpiral,turns=5',
               'GreekKeySpiral,turns=6',
               'GreekKeySpiral,turns=7',
               'GreekKeySpiral,turns=8',
               'GreekKeySpiral,turns=37',

               'ChanTree,k=2',
               'ChanTree',
               'ChanTree,k=4',
               'ChanTree,k=5',
               'ChanTree,k=6',
               'ChanTree,k=7',
               'ChanTree,k=2,n_start=1',
               'ChanTree,n_start=1',
               'ChanTree,k=4,n_start=1',
               'ChanTree,k=5,n_start=1',

               'Rows,width=1',
               'Rows,width=2',
               'Rows,width=3',
               'Rows,width=4',
               'Rows,width=6',
               'Rows,width=15',
               'Rows',
               'Columns,height=1',
               'Columns,height=2',
               'Columns,height=3',
               'Columns,height=4',
               'Columns,height=6',
               'Columns,height=15',
               'Columns',

               'TriangularHypot',
               'TriangularHypot,points=odd',
               'TriangularHypot,points=all',
               'TriangularHypot,points=hex',
               'TriangularHypot,points=hex_rotated',
               'TriangularHypot,points=hex_centred',

               'Corner',
               'Corner,wider=1',
               'Corner,wider=2',
               'Corner,wider=5',
               'Corner,wider=37',

               'PythagoreanTree,tree_type=UMT',
               'PythagoreanTree,tree_type=UMT,coordinates=AC',
               'PythagoreanTree,tree_type=UMT,coordinates=BC',
               'PythagoreanTree,tree_type=UMT,coordinates=PQ',
               'PythagoreanTree,tree_type=UMT,coordinates=SM',
               'PythagoreanTree,tree_type=UMT,coordinates=SC',
               'PythagoreanTree,tree_type=UMT,coordinates=MC',
               'PythagoreanTree',
               'PythagoreanTree,coordinates=AC',
               'PythagoreanTree,coordinates=BC',
               'PythagoreanTree,coordinates=PQ',
               'PythagoreanTree,coordinates=SM',
               'PythagoreanTree,coordinates=SC',
               'PythagoreanTree,coordinates=MC',
               'PythagoreanTree,tree_type=FB',
               'PythagoreanTree,tree_type=FB,coordinates=AC',
               'PythagoreanTree,tree_type=FB,coordinates=BC',
               'PythagoreanTree,tree_type=FB,coordinates=PQ',
               'PythagoreanTree,tree_type=FB,coordinates=SM',
               'PythagoreanTree,tree_type=FB,coordinates=SC',
               'PythagoreanTree,tree_type=FB,coordinates=MC',

               'LTiling',
               'LTiling,L_fill=left',
               'LTiling,L_fill=upper',
               'LTiling,L_fill=ends',
               'LTiling,L_fill=all',

               'HilbertSides',
               'HilbertCurve',
               'HilbertSpiral',

               'DekkingCurve',
               'DekkingCurve,arms=2',
               'DekkingCurve,arms=3',
               'DekkingCurve,arms=4',
               'DekkingCentres',

               'UlamWarburton,parts=octant',
               'UlamWarburton,parts=octant_up',
               'UlamWarburton',
               'UlamWarburton,parts=2',
               'UlamWarburton,parts=1',
               'UlamWarburtonQuarter',
               'UlamWarburtonQuarter,parts=octant_up',
               'UlamWarburtonQuarter,parts=octant',

               'WythoffPreliminaryTriangle',
               'WythoffArray',
               'WythoffArray,x_start=1',
               'WythoffArray,y_start=1',
               'WythoffArray,x_start=1,y_start=1',
               'WythoffArray,x_start=5,y_start=7',

               'MPeaks',
               'MPeaks,n_start=0',

               'AztecDiamondRings',
               'AztecDiamondRings,n_start=0',

               'AnvilSpiral',
               'AnvilSpiral,wider=1',
               'AnvilSpiral,wider=2',
               'AnvilSpiral,wider=9',
               'AnvilSpiral,wider=17',
               'AnvilSpiral,n_start=0',
               'AnvilSpiral,wider=1,n_start=0',
               'AnvilSpiral,wider=2,n_start=0',
               'AnvilSpiral,wider=9,n_start=0',
               'AnvilSpiral,wider=17,n_start=0',

               'Diagonals',
               'Diagonals,direction=up',
               #
               'Diagonals,x_start=1',
               'Diagonals,y_start=1',
               'Diagonals,x_start=1,direction=up',
               'Diagonals,y_start=1,direction=up',
               #
               'Diagonals,x_start=-1',
               'Diagonals,y_start=-1',
               'Diagonals,x_start=-1,direction=up',
               'Diagonals,y_start=-1,direction=up',
               #
               'Diagonals,x_start=2',
               'Diagonals,y_start=2',
               'Diagonals,x_start=2,direction=up',
               'Diagonals,y_start=2,direction=up',
               #
               'Diagonals,x_start=-2',
               'Diagonals,y_start=-2',
               'Diagonals,x_start=-2,direction=up',
               'Diagonals,y_start=-2,direction=up',
               #
               'Diagonals,x_start=6',
               'Diagonals,y_start=6',
               'Diagonals,x_start=6,direction=up',
               'Diagonals,y_start=6,direction=up',
               #
               'Diagonals,x_start=-6',
               'Diagonals,y_start=-6',
               'Diagonals,x_start=-6,direction=up',
               'Diagonals,y_start=-6,direction=up',
               #
               'Diagonals,x_start=3,y_start=6',
               'Diagonals,x_start=-3,y_start=0',
               'Diagonals,x_start=0,y_start=-6',
               'Diagonals,x_start=5,y_start=-2',
               'Diagonals,x_start=-5,y_start=2',
               'Diagonals,x_start=-5,y_start=2',
               'Diagonals,x_start=-5,y_start=-2',
               'Diagonals,x_start=3,y_start=-5',
               'Diagonals,x_start=-3,y_start=5',
               'Diagonals,x_start=-3,y_start=5',
               'Diagonals,x_start=-3,y_start=-5',
               #
               'Diagonals,x_start=3,y_start=6,direction=up',
               'Diagonals,x_start=-3,y_start=0,direction=up',
               'Diagonals,x_start=0,y_start=-6,direction=up',
               'Diagonals,x_start=5,y_start=-2,direction=up',
               'Diagonals,x_start=-5,y_start=2,direction=up',
               'Diagonals,x_start=-5,y_start=2,direction=up',
               'Diagonals,x_start=-5,y_start=-2,direction=up',
               'Diagonals,x_start=3,y_start=-5,direction=up',
               'Diagonals,x_start=-3,y_start=5,direction=up',
               'Diagonals,x_start=-3,y_start=5,direction=up',
               'Diagonals,x_start=-3,y_start=-5,direction=up',

               # 'Diagonals,x_start=20,y_start=10',
               # 'Diagonals,x_start=20,y_start=10
               # 'Diagonals,x_start=3,y_start=6,direction=up',
               # 'Diagonals,x_start=3,y_start=-6,direction=up',
               # 'Diagonals,x_start=-3,y_start=6,direction=up',
               # 'Diagonals,x_start=-3,y_start=-6,direction=up',

               'SierpinskiArrowhead',
               'SierpinskiArrowhead,align=right',
               'SierpinskiArrowhead,align=left',
               'SierpinskiArrowhead,align=diagonal',

               'SierpinskiArrowheadCentres',
               'SierpinskiArrowheadCentres,align=right',
               'SierpinskiArrowheadCentres,align=left',
               'SierpinskiArrowheadCentres,align=diagonal',

               'KochCurve',
               'KochPeaks',
               'KochSnowflakes',
               'KochSquareflakes',
               'KochSquareflakes,inward=>1',

               'CellularRule,rule=84',  # right 2 cell line
               'CellularRule,rule=84,n_start=0',
               'CellularRule,rule=84,n_start=37',

               'CellularRule,rule=14',  # left 2 cell line
               'CellularRule,rule=14,n_start=0',
               'CellularRule,rule=14,n_start=37',

               'CellularRule,rule=20',  # right 1,2 line
               'CellularRule,rule=20,n_start=0',
               'CellularRule,rule=20,n_start=37',

               'CellularRule,rule=6',   # left 1,2 line
               'CellularRule,rule=6,n_start=0',
               'CellularRule,rule=6,n_start=37',

               'PyramidRows',
               'PyramidRows,step=0',
               'PyramidRows,step=1',
               'PyramidRows,step=3',
               'PyramidRows,step=4',
               'PyramidRows,step=5',
               'PyramidRows,step=6',
               'PyramidRows,step=7',
               'PyramidRows,step=37',
               'PyramidRows,align=right',
               'PyramidRows,align=right,step=0',
               'PyramidRows,align=right,step=1',
               'PyramidRows,align=right,step=3',
               'PyramidRows,align=right,step=4',
               'PyramidRows,align=right,step=5',
               'PyramidRows,align=right,step=6',
               'PyramidRows,align=right,step=7',
               'PyramidRows,align=right,step=37',
               'PyramidRows,align=left',
               'PyramidRows,align=left,step=0',
               'PyramidRows,align=left,step=1',
               'PyramidRows,align=left,step=3',
               'PyramidRows,align=left,step=4',
               'PyramidRows,align=left,step=5',
               'PyramidRows,align=left,step=6',
               'PyramidRows,align=left,step=7',
               'PyramidRows,align=left,step=37',

               'OctagramSpiral',
               'OctagramSpiral,n_start=0',
               'OctagramSpiral,n_start=37',

               'Staircase',
               'Staircase,n_start=0',
               'Staircase,n_start=37',
               'StaircaseAlternating',
               'StaircaseAlternating,n_start=0',
               'StaircaseAlternating,n_start=37',
               'StaircaseAlternating,end_type=square',
               'StaircaseAlternating,end_type=square,n_start=0',
               'StaircaseAlternating,end_type=square,n_start=37',

               'R5DragonCurve',
               'R5DragonCurve,arms=2',
               'R5DragonCurve,arms=3',
               'R5DragonCurve,arms=4',
               'R5DragonMidpoint',
               'R5DragonMidpoint,arms=2',
               'R5DragonMidpoint,arms=3',
               'R5DragonMidpoint,arms=4',

               'PyramidSides',

               'CornerReplicate',

               'DragonCurve',
               'DragonCurve,arms=2',
               'DragonCurve,arms=3',
               'DragonCurve,arms=4',
               'DragonRounded',
               'DragonRounded,arms=2',
               'DragonRounded,arms=3',
               'DragonRounded,arms=4',
               'DragonMidpoint',
               'DragonMidpoint,arms=2',
               'DragonMidpoint,arms=3',
               'DragonMidpoint,arms=4',

               'TerdragonCurve',
               'TerdragonCurve,arms=2',
               'TerdragonCurve,arms=3',
               'TerdragonCurve,arms=4',
               'TerdragonCurve,arms=5',
               'TerdragonCurve,arms=6',

               'TerdragonRounded',
               'TerdragonRounded,arms=2',
               'TerdragonRounded,arms=3',
               'TerdragonRounded,arms=4',
               'TerdragonRounded,arms=5',
               'TerdragonRounded,arms=6',

               'TerdragonMidpoint',
               'TerdragonMidpoint,arms=2',
               'TerdragonMidpoint,arms=3',
               'TerdragonMidpoint,arms=4',
               'TerdragonMidpoint,arms=5',
               'TerdragonMidpoint,arms=6',

               'HexSpiral',
               'HexSpiral,wider=1',
               'HexSpiral,wider=2',
               'HexSpiral,wider=3',
               'HexSpiral,wider=4',
               'HexSpiral,wider=5',
               'HexSpiral,wider=37',
               'HexSpiralSkewed',
               'HexSpiralSkewed,wider=1',
               'HexSpiralSkewed,wider=2',
               'HexSpiralSkewed,wider=3',
               'HexSpiralSkewed,wider=4',
               'HexSpiralSkewed,wider=5',
               'HexSpiralSkewed,wider=37',

               'Hypot',
               'Hypot,points=even',
               'Hypot,points=odd',
               'HypotOctant',
               'HypotOctant,points=even',
               'HypotOctant,points=odd',

               'DiamondArms',
               'SquareArms',
               'HexArms',

               'PentSpiral',
               'PentSpiral,n_start=0',
               'PentSpiral,n_start=37',
               'PentSpiralSkewed',
               'PentSpiralSkewed,n_start=0',
               'PentSpiralSkewed,n_start=37',

               'CellularRule,rule=16', # right line
               'CellularRule,rule=16,n_start=0',
               'CellularRule,rule=16,n_start=37',
               'CellularRule,rule=24', # right line
               'CellularRule,rule=48', # right line

               'CellularRule,rule=2',  # left line
               'CellularRule,rule=2,n_start=0',
               'CellularRule,rule=2,n_start=37',
               'CellularRule,rule=10', # left line
               'CellularRule,rule=34', # left line

               'CellularRule,rule=4',  # centre line
               'CellularRule,rule=4,n_start=0',
               'CellularRule,rule=4,n_start=37',
               'CellularRule,rule=12', # centre line
               'CellularRule,rule=36', # centre line

               'CellularRule,rule=206', # left solid
               'CellularRule,rule=206,n_start=0',
               'CellularRule,rule=206,n_start=37',

               'CellularRule,rule=18',  # Sierpinski
               'CellularRule,rule=18,n_start=0',
               'CellularRule,rule=18,n_start=37',

               'CellularRule,rule=60',
               'CellularRule,rule=18,n_start=0',
               'CellularRule,rule=18,n_start=37',
               'CellularRule,rule=220', # right half solid
               'CellularRule,rule=220,n_start=0',
               'CellularRule,rule=220,n_start=37',
               'CellularRule,rule=222', # solid

               'CoprimeColumns',
               'DivisibleColumns',
               'DivisibleColumns,divisor_type=proper',

               'FractionsTree',

               'SierpinskiTriangle',
               'SierpinskiTriangle,align=right',
               'SierpinskiTriangle,align=left',
               'SierpinskiTriangle,align=diagonal',
               'SierpinskiTriangle,n_start=37',
               'SierpinskiTriangle,n_start=37,align=right',
               'SierpinskiTriangle,n_start=37,align=left',
               'SierpinskiTriangle,n_start=37,align=diagonal',

               '*ToothpickUpist',

               '*HTree',

               'FlowsnakeCentres',
               'FlowsnakeCentres,arms=2',
               'FlowsnakeCentres,arms=3',
               'Flowsnake',
               'Flowsnake,arms=2',
               'Flowsnake,arms=3',

               'ImaginaryBase',
               'ImaginaryBase,radix=3',
               'ImaginaryBase,radix=4',
               'ImaginaryBase,radix=5',
               'ImaginaryBase,radix=6',
               'ImaginaryBase,radix=37',

               'ImaginaryHalf',
               'ImaginaryHalf,digit_order=XXY',
               'ImaginaryHalf,digit_order=YXX',
               'ImaginaryHalf,digit_order=XnXY',
               'ImaginaryHalf,digit_order=XnYX',
               'ImaginaryHalf,digit_order=YXnX',
               'ImaginaryHalf,digit_order=XXY,radix=3',
               'ImaginaryHalf,radix=37',
               'ImaginaryHalf,radix=3',
               'ImaginaryHalf,radix=4',
               'ImaginaryHalf,radix=5',
               'ImaginaryHalf,radix=6',

               'FactorRationals',
               'FactorRationals,sign_encoding=odd/even',
               'FactorRationals,sign_encoding=negabinary',
               'FactorRationals,sign_encoding=revbinary',
               'FactorRationals,sign_encoding=spread',

               'PowerArray',
               'PowerArray,radix=3',
               'PowerArray,radix=4',

               '*ToothpickTree',
               '*ToothpickTree,parts=1',
               '*ToothpickTree,parts=2',
               '*ToothpickTree,parts=3',
               '*ToothpickTree,parts=octant',
               '*ToothpickTree,parts=octant_up',
               '*ToothpickTree,parts=wedge',

               '*ToothpickReplicate',
               '*ToothpickReplicate,parts=1',
               '*ToothpickReplicate,parts=2',
               '*ToothpickReplicate,parts=3',

               '*LCornerReplicate',

               '*LCornerTree',
               '*LCornerTree,parts=3',
               '*LCornerTree,parts=2',
               '*LCornerTree,parts=1',
               '*LCornerTree,parts=octant',
               '*LCornerTree,parts=octant+1',
               '*LCornerTree,parts=octant_up',
               '*LCornerTree,parts=octant_up+1',
               '*LCornerTree,parts=wedge',
               '*LCornerTree,parts=wedge+1',
               '*LCornerTree,parts=diagonal-1',
               '*LCornerTree,parts=diagonal',

               'ZOrderCurve',
               'ZOrderCurve,radix=3',
               'ZOrderCurve,radix=9',
               'ZOrderCurve,radix=37',

               'DiagonalRationals',
               'DiagonalRationals,direction=up',

               'HeptSpiralSkewed',
               'HeptSpiralSkewed,n_start=0',
               'HeptSpiralSkewed,n_start=37',

               '*OneOfEight,parts=wedge',
               '*OneOfEight,parts=octant_up',
               '*OneOfEight',
               '*OneOfEight,parts=4',
               '*OneOfEight,parts=1',
               '*OneOfEight,parts=octant',
               '*OneOfEight,parts=3mid',
               '*OneOfEight,parts=3side',

               '*ToothpickSpiral',
               '*ToothpickSpiral,n_start=0',
               '*ToothpickSpiral,n_start=37',

               'ComplexPlus',
               'ComplexPlus,realpart=2',
               'ComplexPlus,realpart=3',
               'ComplexPlus,realpart=4',
               'ComplexPlus,realpart=5',

               'PyramidSpiral',
               'PyramidSpiral,n_start=0',
               'PyramidSpiral,n_start=37',

               'GrayCode,apply_type=TsF',
               'GrayCode,apply_type=FsT',
               'GrayCode,apply_type=Ts',
               'GrayCode,apply_type=Fs',
               'GrayCode,apply_type=sT',
               'GrayCode,apply_type=sF',

               'GrayCode,radix=3,apply_type=TsF',
               'GrayCode,radix=3,apply_type=FsT',
               'GrayCode,radix=3,apply_type=Ts',
               'GrayCode,radix=3,apply_type=Fs',
               'GrayCode,radix=3,apply_type=sT',
               'GrayCode,radix=3,apply_type=sF',

               'GrayCode,radix=3,gray_type=modular,apply_type=TsF',
               'GrayCode,radix=3,gray_type=modular,apply_type=Ts',
               'GrayCode,radix=3,gray_type=modular,apply_type=Fs',
               'GrayCode,radix=3,gray_type=modular,apply_type=FsT',
               'GrayCode,radix=3,gray_type=modular,apply_type=sT',
               'GrayCode,radix=3,gray_type=modular,apply_type=sF',

               'GrayCode,radix=4,apply_type=TsF',
               'GrayCode,radix=4,apply_type=FsT',
               'GrayCode,radix=4,apply_type=Ts',
               'GrayCode,radix=4,apply_type=Fs',
               'GrayCode,radix=4,apply_type=sT',
               'GrayCode,radix=4,apply_type=sF',

               'GrayCode,radix=4,gray_type=modular,apply_type=TsF',
               'GrayCode,radix=4,gray_type=modular,apply_type=Ts',
               'GrayCode,radix=4,gray_type=modular,apply_type=Fs',
               'GrayCode,radix=4,gray_type=modular,apply_type=FsT',
               'GrayCode,radix=4,gray_type=modular,apply_type=sT',
               'GrayCode,radix=4,gray_type=modular,apply_type=sF',

               'GrayCode,radix=5,apply_type=TsF',
               'GrayCode,radix=5,apply_type=FsT',
               'GrayCode,radix=5,apply_type=Ts',
               'GrayCode,radix=5,apply_type=Fs',
               'GrayCode,radix=5,apply_type=sT',
               'GrayCode,radix=5,apply_type=sF',

               'GrayCode,radix=5,gray_type=modular,apply_type=TsF',
               'GrayCode,radix=5,gray_type=modular,apply_type=Ts',
               'GrayCode,radix=5,gray_type=modular,apply_type=Fs',
               'GrayCode,radix=5,gray_type=modular,apply_type=FsT',
               'GrayCode,radix=5,gray_type=modular,apply_type=sT',
               'GrayCode,radix=5,gray_type=modular,apply_type=sF',

               'GrayCode,radix=6,apply_type=TsF',
               'GrayCode,radix=6,apply_type=FsT',
               'GrayCode,radix=6,apply_type=Ts',
               'GrayCode,radix=6,apply_type=Fs',
               'GrayCode,radix=6,apply_type=sT',
               'GrayCode,radix=6,apply_type=sF',

               'GrayCode,radix=6,gray_type=modular,apply_type=TsF',
               'GrayCode,radix=6,gray_type=modular,apply_type=Ts',
               'GrayCode,radix=6,gray_type=modular,apply_type=Fs',
               'GrayCode,radix=6,gray_type=modular,apply_type=FsT',
               'GrayCode,radix=6,gray_type=modular,apply_type=sT',
               'GrayCode,radix=6,gray_type=modular,apply_type=sF',


               'CellularRule',
               'CellularRule,rule=0',   # single cell
               'CellularRule,rule=8',   # single cell
               'CellularRule,rule=32',  # single cell
               'CellularRule,rule=40',  # single cell
               'CellularRule,rule=64',  # single cell
               'CellularRule,rule=72',  # single cell
               'CellularRule,rule=96',  # single cell
               'CellularRule,rule=104', # single cell
               'CellularRule,rule=128', # single cell
               'CellularRule,rule=136', # single cell
               'CellularRule,rule=160', # single cell
               'CellularRule,rule=168', # single cell
               'CellularRule,rule=192', # single cell
               'CellularRule,rule=200', # single cell
               'CellularRule,rule=224', # single cell
               'CellularRule,rule=232', # single cell

               'CellularRule,rule=50',  # solid every second cell
               'CellularRule,rule=50,n_start=0',
               'CellularRule,rule=50,n_start=37',
               'CellularRule,rule=58',  # solid every second cell

               'CellularRule54',
               'CellularRule54,n_start=0',
               'CellularRule54,n_start=37',
               'CellularRule57',
               'CellularRule57,n_start=0',
               'CellularRule57,n_start=37',
               'CellularRule57,mirror=1',
               'CellularRule190,n_start=0',
               'CellularRule190',
               'CellularRule190',
               'CellularRule190,mirror=1',
               'CellularRule190,mirror=1,n_start=0',

               'AlternatePaper',
               'AlternatePaper,arms=2',
               'AlternatePaper,arms=3',
               'AlternatePaper,arms=4',
               'AlternatePaper,arms=5',
               'AlternatePaper,arms=6',
               'AlternatePaper,arms=7',
               'AlternatePaper,arms=8',

               'AlternatePaperMidpoint',
               'AlternatePaperMidpoint,arms=2',
               'AlternatePaperMidpoint,arms=3',
               'AlternatePaperMidpoint,arms=4',
               'AlternatePaperMidpoint,arms=5',
               'AlternatePaperMidpoint,arms=6',
               'AlternatePaperMidpoint,arms=7',
               'AlternatePaperMidpoint,arms=8',

               'GosperReplicate',
               'GosperSide',
               'GosperIslands',

               'CubicBase',

               'PeanoCurve',
               'PeanoCurve,radix=2',
               'PeanoCurve,radix=4',
               'PeanoCurve,radix=5',
               'PeanoCurve,radix=17',

               'KnightSpiral',

               'DiagonalsAlternating',

               'GcdRationals',
               'GcdRationals,pairs_order=rows_reverse',
               'GcdRationals,pairs_order=diagonals_down',
               'GcdRationals,pairs_order=diagonals_up',

               'CCurve',

               'ComplexMinus',
               'ComplexMinus,realpart=2',
               'ComplexMinus,realpart=3',
               'ComplexMinus,realpart=4',
               'ComplexMinus,realpart=5',
               'ComplexRevolving',

               'SierpinskiCurve',
               'SierpinskiCurve,arms=2',
               'SierpinskiCurve,arms=3',
               'SierpinskiCurve,diagonal_spacing=5',
               'SierpinskiCurve,straight_spacing=5',
               'SierpinskiCurve,diagonal_spacing=3,straight_spacing=7',
               'SierpinskiCurve,diagonal_spacing=3,straight_spacing=7,arms=7',
               'SierpinskiCurve,arms=4',
               'SierpinskiCurve,arms=5',
               'SierpinskiCurve,arms=6',
               'SierpinskiCurve,arms=7',
               'SierpinskiCurve,arms=8',

               'TriangleSpiralSkewed',
               'TriangleSpiralSkewed,n_start=37',
               'TriangleSpiralSkewed,skew=right',
               'TriangleSpiralSkewed,skew=right,n_start=37',
               'TriangleSpiralSkewed,skew=up',
               'TriangleSpiralSkewed,skew=up,n_start=37',
               'TriangleSpiralSkewed,skew=down',
               'TriangleSpiralSkewed,skew=down,n_start=37',

               'DiagonalsOctant',
               'DiagonalsOctant,direction=up',

               'HIndexing',

               'SierpinskiCurveStair',
               'SierpinskiCurveStair,diagonal_length=2',
               'SierpinskiCurveStair,diagonal_length=3',
               'SierpinskiCurveStair,diagonal_length=4',
               'SierpinskiCurveStair,arms=2',
               'SierpinskiCurveStair,arms=3,diagonal_length=2',
               'SierpinskiCurveStair,arms=4',
               'SierpinskiCurveStair,arms=5',
               'SierpinskiCurveStair,arms=6,diagonal_length=5',
               'SierpinskiCurveStair,arms=7',
               'SierpinskiCurveStair,arms=8',

               'QuadricCurve',
               'QuadricIslands',

               'CfracDigits,radix=1',
               'CfracDigits',
               'CfracDigits,radix=3',
               'CfracDigits,radix=4',
               'CfracDigits,radix=37',

               'RationalsTree,tree_type=L',
               'RationalsTree,tree_type=HCS',
               'RationalsTree',
               'RationalsTree,tree_type=CW',
               'RationalsTree,tree_type=AYT',
               'RationalsTree,tree_type=Bird',
               'RationalsTree,tree_type=Drib',

               'WunderlichSerpentine,radix=2',
               'WunderlichSerpentine',
               'WunderlichSerpentine,serpentine_type=100_000_000',
               'WunderlichSerpentine,serpentine_type=000_000_001',
               'WunderlichSerpentine,radix=4',
               'WunderlichSerpentine,radix=5,serpentine_type=coil',

               'DigitGroups',
               'DigitGroups,radix=3',
               'DigitGroups,radix=4',
               'DigitGroups,radix=5',
               'DigitGroups,radix=37',

               'QuintetReplicate',
               'QuintetCurve',
               'QuintetCurve,arms=2',
               'QuintetCurve,arms=3',
               'QuintetCurve,arms=4',
               'QuintetCentres',
               'QuintetCentres,arms=2',
               'QuintetCentres,arms=3',
               'QuintetCentres,arms=4',

               'TriangleSpiral',
               'TriangleSpiral,n_start=37',

               # 'File',


               'PixelRings',
               'FilledRings',

               'CretanLabyrinth',

               'AR2W2Curve',
               'AR2W2Curve,start_shape=D2',
               'AR2W2Curve,start_shape=B2',
               'AR2W2Curve,start_shape=B1rev',
               'AR2W2Curve,start_shape=D1rev',
               'AR2W2Curve,start_shape=A2rev',
               'BetaOmega',
               'KochelCurve',
               'CincoCurve',

               'WunderlichMeander',
               'FibonacciWordFractal',

               'DiamondSpiral',

               'SquareReplicate',

               # module list end

               # cellular 0 to 255
               (map {("CellularRule,rule=$_",
                      "CellularRule,rule=$_,n_start=0",
                      "CellularRule,rule=$_,n_start=37")} 0..255),

              );
foreach (@modules) { s/^\*// }

{
  require Math::NumSeq::PlanePathDelta;
  require Math::NumSeq::PlanePathTurn;
  require Math::NumSeq::PlanePathN;

  foreach my $mod (@modules) {
    next unless want_planepath($mod);

    my $bad = 0;
    foreach my $elem (
                      ['Math::NumSeq::PlanePathDelta','delta_type'],
                      ['Math::NumSeq::PlanePathCoord','coordinate_type'],
                      ['Math::NumSeq::PlanePathTurn','turn_type'],
                      ['Math::NumSeq::PlanePathN','line_type'],
                     ) {
      my ($class, $pname) = @$elem;

      foreach my $param (@{$class->parameter_info_hash
                             ->{$pname}->{'choices'}}) {
        next unless want_coordinate($param);

        MyTestHelpers::diag ("$mod $param");
        ### $mod
        ### $param

        my $seq = $class->new (planepath => $mod,
                               $pname => $param);

        my $planepath_object = $seq->{'planepath_object'};
        ### planepath_object: ref $planepath_object

        my $i_start = $seq->i_start;
        if (! defined $i_start) {
          die "Oops, i_start=undef";
        }
        my $characteristic_integer = $seq->characteristic('integer') || 0;
        my $saw_characteristic_integer = 1;
        my $saw_characteristic_integer_at = '';
        my $saw_values_min    = 999999999;
        my $saw_values_max    = -999999999;
        my $saw_values_min_at = 'sentinel';
        my $saw_values_max_at = 'sentinel';
        my $saw_increasing = 1;
        my $saw_non_decreasing = 1;
        my $saw_increasing_at = '[default]';
        my $saw_non_decreasing_at = '[default]';
        my $prev_value;

        my $count = 0;
        my $i_limit = 800;
        if ($mod =~ /Vogel|Theod|Archim/
            && $param =~ /axis|[XY]_neg|diagonal/i) {
          $i_limit = 20;
        }
        if ($mod =~ /Hypot|PixelRings|FilledRings/
            && $param =~ /axis|[XY]_neg|diagonal/i) {
          $i_limit = 50;
        }
        if ($mod =~ /CellularRule/
            && $param =~ /axis|[XY]_neg|diagonal/i) {
          $i_limit = 80;
        }
        my $i_end = $i_start + $i_limit;
        ### $i_limit

        my @i_extra;
        if (my $delta_type = $seq->{'delta_type'}) {
          foreach my $m ('min','max') {
            if (my $coderef = $planepath_object->can("_NumSeq_Delta_${delta_type}_${m}_n")) {
              push @i_extra, $planepath_object->$coderef();
            }
          }
        }

        foreach my $i ($i_start .. $i_end, @i_extra) {
          my $value = $seq->ith($i);
          ### $i
          ### $value
          next if ! defined $value;
          $count++;

          if ($saw_characteristic_integer) {
            if ($value != int($value)) {
              $saw_characteristic_integer = 0;
              $saw_characteristic_integer_at = "i=$i value=$value";
            }
          }

          if ($value < $saw_values_min) {
            $saw_values_min = $value;
            if (my ($x,$y) = $seq->{'planepath_object'}->n_to_xy($i)) {
              $saw_values_min_at = "i=$i xy=$x,$y";
            } else {
              $saw_values_min_at = "i=$i";
            }
          }
          if ($value > $saw_values_max) {
            $saw_values_max = $value;
            $saw_values_max_at = "i=$i";
          }

          # ### $value
          # ### $prev_value
          if (defined $prev_value) {
            if (abs($value - $prev_value) < 0.0000001) {
              $prev_value = $value;
            }
            if ($value <= $prev_value
                && ! is_nan($prev_value)
                && ! ($value==pos_infinity() && $prev_value==pos_infinity())) {
              # ### not increasing ...
              if ($saw_increasing) {
                $saw_increasing = 0;
                $saw_increasing_at = "i=$i value=$value prev_value=$prev_value";
              }

              if ($value < $prev_value) {
                if ($saw_non_decreasing) {
                  $saw_non_decreasing = 0;
                  $saw_non_decreasing_at = "i=$i";
                }
              }
            }
          }
          $prev_value = $value;
        }
        ### $count
        next if $count == 0;

        ### $saw_values_min
        ### $saw_values_min_at
        ### $saw_values_max
        ### $saw_values_max_at

        my $values_min = $seq->values_min;
        my $values_max = $seq->values_max;
        if (! defined $values_min) {
          if ($saw_values_min >= -3 && $count >= 3) {
            MyTestHelpers::diag ("$mod $param values_min=undef vs saw_values_min=$saw_values_min apparent lower bound at $saw_values_min_at");
          }
          $values_min = $saw_values_min;
        }
        if (! defined $values_max) {
          if ($saw_values_max <= 3 && $count >= 3) {
            MyTestHelpers::diag ("$mod $param values_max=undef vs saw_values_max=$saw_values_max apparent upper bound at $saw_values_max_at");
          }
          $values_max = $saw_values_max;
        }

        if (my $coderef = $planepath_object->can("_NumSeq_${param}_max_is_supremum")) {
          if ($planepath_object->$coderef) {
            if ($saw_values_max == $values_max) {
              MyTestHelpers::diag ("$mod $param values_max=$values_max vs saw_values_max=$saw_values_max at $saw_values_max_at supposed to be supremum only");
              MyTestHelpers::diag ("  (planepath_object ",ref $seq->{'planepath_object'},")");
              $bad++;
            }
            if ($saw_values_max < $values_max) {
              $saw_values_max  = $values_max;
              $saw_values_max_at = 'supremum';
            }
          }
        }
        if (my $coderef = $planepath_object->can("_NumSeq_${param}_min_is_infimum")) {
          if ($planepath_object->$coderef()) {
            if ($saw_values_min == $values_min) {
              MyTestHelpers::diag ("$mod $param values_min=$values_min vs saw_values_min=$saw_values_min at $saw_values_min_at supposed to be infimum only");
              MyTestHelpers::diag ("  (planepath_object ",ref $seq->{'planepath_object'},")");
            }
            if ($saw_values_min > $values_min) {
              $saw_values_min  = $values_min;
              $saw_values_min_at = 'infimum';
            }
          }
        }



        # these come arbitrarily close to dX==dY, in general, probably
        if (($mod eq 'MultipleRings,step=2'
             || $mod eq 'MultipleRings,step=3'
             || $mod eq 'MultipleRings,step=5'
             || $mod eq 'MultipleRings,step=7'
             || $mod eq 'MultipleRings,step=37'
            )
            && $param eq 'AbsDiff'
            && $saw_values_min > 0 && $saw_values_min < 0.3) {
          $saw_values_min = 0;
          $saw_values_min_at = 'override';
        }

        # supremum +/- 1 without ever actually reaching
        if (($mod eq 'MultipleRings'
            )
            && ($param eq 'dX'
                || $param eq 'dY'
               )) {
          $saw_values_min = -1;
          $saw_values_min_at = 'override';
        }

        # if (($mod eq 'MultipleRings,step=1'
        #      || $mod eq 'MultipleRings,step=2'
        #      || $mod eq 'MultipleRings,step=3'
        #      || $mod eq 'MultipleRings,step=4'
        #      || $mod eq 'MultipleRings,step=5'
        #      || $mod eq 'MultipleRings,step=6'
        #      || $mod eq 'MultipleRings'
        #     )
        #     && ($param eq 'dX'
        #         || $param eq 'dY'
        #         || $param eq 'Dist'
        #        )) {
        #   my ($step) = ($mod =~ /MultipleRings,step=(\d+)/);
        #   $step ||= 6;
        #   if (-$saw_values_min > 2*PI()/$step*0.85
        #       && -$saw_values_min < 2*PI()/$step) {
        #     $saw_values_min = -2*PI() / $step;
        #     $saw_values_min_at = 'override';
        #   }
        #   if ($saw_values_max > 2*PI()/$step*0.85
        #       && $saw_values_max < 2*PI()/$step) {
        #     $saw_values_max = 2*PI() / $step;
        #     $saw_values_max_at = 'override';
        #   }
        # }
        if (($mod eq 'MultipleRings,step=7'
             || $mod eq 'MultipleRings,step=8'
            )
            && ($param eq 'dY'
               )) {
          if (-$saw_values_min > 0.9
              && -$saw_values_min < 1) {
            $saw_values_min = -1;
            $saw_values_min_at = 'override';
          }
          if ($saw_values_max > 0.9
              && $saw_values_max < 1) {
            $saw_values_max = 1;
            $saw_values_max_at = 'override';
          }
        }
        if (($mod eq 'MultipleRings,step=7'
             || $mod eq 'MultipleRings,step=8'
            )
            && ($param eq 'dX'
               )) {
          if (-$saw_values_min > 0.9
              && -$saw_values_min < 1) {
            $saw_values_min = -1;
            $saw_values_min_at = 'override';
          }
        }

        # approach 360 without ever actually reaching
        if (($mod eq 'SacksSpiral'
             || $mod eq 'TheodorusSpiral'
             || $mod eq 'Hypot'
             || $mod eq 'MultipleRings,step=8'
             || $mod eq 'MultipleRings,step=37'
            )
            && ($param eq 'Dir4'
               )
            && $saw_values_max > 3.7 && $saw_values_max < 4
           ) {
          $saw_values_max = 4;
          $saw_values_max_at = 'override';
        }
        if (($mod eq 'SacksSpiral'
             || $mod eq 'TheodorusSpiral'
             || $mod eq 'Hypot'
             || $mod eq 'MultipleRings,step=8'
             || $mod eq 'MultipleRings,step=37'
            )
            && ($param eq 'TDir6'
               )
            && $saw_values_max > 5.55 && $saw_values_max < 6) {
          $saw_values_max = 6;
          $saw_values_max_at = 'override';
        }

        # approach 0 without ever actually reaching
        if (($mod eq 'MultipleRings,step=8'
             || $mod eq 'MultipleRings,step=37'
            )
            && ($param eq 'Dir4'
               )) {
          $saw_values_min = 0;
          $saw_values_min_at = 'override';
        }
        if (($mod eq 'MultipleRings,step=8'
             || $mod eq 'MultipleRings,step=37'
            )
            && ($param eq 'TDir6'
               )) {
          $saw_values_min = 0;
          $saw_values_min_at = 'override';
        }

        # not enough values to see these decreasing
        if (($mod eq 'SquareSpiral,wider=37'
            )
            && ($param eq 'dY')) {
          $saw_values_min = -1;
          $saw_values_min_at = 'override';
        }
        if (($mod eq 'SquareSpiral,wider=37'
            )
            && ($param eq 'Dir4')) {
          $saw_values_max = 3;
          $saw_values_max_at = 'override';
        }
        if (($mod eq 'SquareSpiral,wider=37'
            )
            && ($param eq 'TDir6')) {
          $saw_values_max = 4.5;
          $saw_values_max_at = 'override';
        }

        # not enough values to see near supremum
        if (($mod eq 'ZOrderCurve,radix=37'
            )
            && ($param eq 'Dir4'
                || $param eq 'TDir6'
               )) {
          $saw_values_max = $values_max;
          $saw_values_max_at = 'override';
        }
        # Turn4 maximum is at N=radix*radix-1
        if (($mod eq 'ZOrderCurve,radix=37'
             && $param eq 'Turn4'
             && $i_end < 37*37-1
            )) {
          $saw_values_max = $values_max;
          $saw_values_max_at = 'override';
        }

        # Turn4 maximum is at N=8191
        if (($mod eq 'LCornerReplicate'
             && $param eq 'Turn4'
             && $i_end < 8191
            )) {
          $saw_values_max = $values_max;
          $saw_values_max_at = 'override';
        }

        if (abs ($values_min - $saw_values_min) > 0.001) {
          MyTestHelpers::diag ("$mod $param values_min=$values_min vs saw_values_min=$saw_values_min at $saw_values_min_at (to i_end=$i_end)");
          MyTestHelpers::diag ("  (planepath_object ",ref $seq->{'planepath_object'},")");
          $bad++;
        }
        if (abs ($values_max - $saw_values_max) > 0.001) {
          MyTestHelpers::diag ("$mod $param values_max=$values_max vs saw_values_max=$saw_values_max at $saw_values_max_at (to i_end=$i_end)");
          MyTestHelpers::diag ("  (planepath_object ",ref $seq->{'planepath_object'},")");
          $bad++;
        }


        #-------------------


        my $increasing = $seq->characteristic('increasing');
        my $non_decreasing = $seq->characteristic('non_decreasing');
        $increasing ||= 0;
        $non_decreasing ||= 0;

        # not enough values to see these decreasing
        if ($mod eq 'DigitGroups,radix=37'
            && $param eq 'Radius'
            && $i_end < 37*37) {
          $saw_characteristic_integer = 0;
        }

        # not enough values to see these decreasing
        if (($mod eq 'ZOrderCurve,radix=9'
             || $mod eq 'ZOrderCurve,radix=37'
             || $mod eq 'PeanoCurve,radix=17'
             || $mod eq 'DigitGroups,radix=37'
             || $mod eq 'SquareSpiral,wider=37'
             || $mod eq 'HexSpiral,wider=37'
             || $mod eq 'HexSpiralSkewed,wider=37'
             || $mod eq 'ComplexPlus,realpart=2'
             || $mod eq 'ComplexPlus,realpart=3'
             || $mod eq 'ComplexPlus,realpart=4'
             || $mod eq 'ComplexPlus,realpart=5'
             || $mod eq 'ComplexMinus,realpart=3'
             || $mod eq 'ComplexMinus,realpart=4'
             || $mod eq 'ComplexMinus,realpart=5'
            )
            && ($param eq 'Y'
                || $param eq 'Product')) {
          $saw_increasing_at = 'override';
          $saw_increasing = 0;
          $saw_non_decreasing = 0;
        }

        # not enough values to see these decreasing
        if (($mod eq 'ComplexPlus,realpart=2'
             || $mod eq 'ComplexPlus,realpart=3'
             || $mod eq 'ComplexPlus,realpart=4'
             || $mod eq 'ComplexPlus,realpart=5'
             || $mod eq 'ComplexMinus,realpart=5'
             || $mod eq 'TerdragonMidpoint'
             || $mod eq 'TerdragonMidpoint,arms=2'
             || $mod eq 'TerdragonMidpoint,arms=3'
             || $mod eq 'TerdragonCurve'
             || $mod eq 'TerdragonCurve,arms=2'
             || $mod eq 'TerdragonCurve,arms=3'
             || $mod eq 'TerdragonRounded'
             || $mod eq 'Flowsnake'
             || $mod eq 'Flowsnake,arms=2'
             || $mod eq 'FlowsnakeCentres'
             || $mod eq 'FlowsnakeCentres,arms=2'
             || $mod eq 'GosperSide'
             || $mod eq 'GosperIslands'
             || $mod eq 'QuintetCentres'
             || $mod eq 'QuintetCentres,arms=2'
             || $mod eq 'QuintetCentres,arms=3'
            )
            && ($param eq 'X_axis'
                || $param eq 'Y_axis'
                || $param eq 'X_neg'
                || $param eq 'Y_neg'
                || $param =~ /Diagonal/
               )) {
          $saw_increasing = 0;
          $saw_increasing_at = 'override';
          $saw_non_decreasing = 0;
        }

        if ($mod eq 'QuintetCurve'
            && $i_end < 5938  # first decrease
            && $param eq 'Diagonal_SE') {
          $saw_increasing = 0;
          $saw_increasing_at = 'override';
          $saw_non_decreasing = 0;
        }
        if ($mod eq 'QuintetCentres'
            && $i_end < 5931 # first decreasing
            && $param eq 'Diagonal_SE') {
          $saw_increasing = 0;
          $saw_increasing_at = 'override';
          $saw_non_decreasing = 0;
        }

        if ($mod eq 'ImaginaryBase,radix=37'
            && $i_end < 1369  # N of first Y coordinate decrease
            && $param eq 'Y') {
          $saw_increasing = 0;
          $saw_increasing_at = 'override';
          $saw_non_decreasing = 0;
        }
        # if ($mod eq 'ImaginaryBase,radix=37'
        #     $param eq 'Diagonal_NW'
        #         || $param eq 'Diagonal_NW'
        #         || $param eq 'Diagonal_SS'
        #         || $param eq 'Diagonal_SE')
        #     && $i_end < 74) {
        #   $saw_increasing = 0;
        # $saw_increasing_at = 'override';
        #   $saw_non_decreasing = 0;
        # }

        if ($mod eq 'ImaginaryHalf,radix=37'
            && $i_end < 1369  # N of first Y coordinate decrease
            && $param eq 'Y') {
          $saw_increasing = 0;
          $saw_increasing_at = 'override';
          $saw_non_decreasing = 0;
        }
        if ($mod eq 'ImaginaryHalf,radix=37'
            && $i_end < 99974  # first decrease
            && $param eq 'Diagonal') {
          $saw_increasing = 0;
          $saw_increasing_at = 'override';
          $saw_non_decreasing = 0;
        }
        if ($mod eq 'ImaginaryHalf,radix=37'
            && $i_end < 2702  # first decreasing
            && $param eq 'Diagonal_NW') {
          $saw_increasing = 0;
          $saw_increasing_at = 'override';
          $saw_non_decreasing = 0;
        }

        # not enough values to see these decreasing
        if (($mod eq 'DigitGroups,radix=37'
            )
            && ($param eq 'X_axis'
                || $param eq 'Y_axis'
               )) {
          $saw_increasing = 0;
          $saw_increasing_at = 'override';
          $saw_non_decreasing = 0;
        }

        # not enough values to see these decreasing
        if (($mod eq 'PeanoCurve,radix=2'
             || $mod eq 'PeanoCurve,radix=4'
             || $mod eq 'PeanoCurve,radix=5'
             || $mod eq 'PeanoCurve,radix=17'
            )
            && ($param eq 'Diagonal'
               )) {
          $saw_increasing = 0;
          $saw_increasing_at = 'override';
          $saw_non_decreasing = 0;
        }

        if (($mod eq 'SquareSpiral,wider=37'
            )
            && ($param eq 'Dir4'
                || $param eq 'TDir6')) {
          $saw_non_decreasing = 0;
        }

        if ($count > 1 && $increasing ne $saw_increasing) {
          MyTestHelpers::diag ("$mod $param increasing=$increasing vs saw_increasing=$saw_increasing at $saw_increasing_at (to i_end=$i_end)");
          MyTestHelpers::diag ("  (planepath_object ",ref $seq->{'planepath_object'},")");
          $bad++;
        }
        if ($count > 1 && $non_decreasing ne $saw_non_decreasing) {
          MyTestHelpers::diag ("$mod $param non_decreasing=$non_decreasing vs saw_non_decreasing=$saw_non_decreasing at $saw_non_decreasing_at (to i_end=$i_end)");
          MyTestHelpers::diag ("  (planepath_object ",ref $seq->{'planepath_object'},")");
          $bad++;
        }

        if ($characteristic_integer != $saw_characteristic_integer) {
          MyTestHelpers::diag ("$mod $param characteristic_integer=$characteristic_integer vs saw_characteristic_integer=$saw_characteristic_integer at $saw_characteristic_integer_at");
          MyTestHelpers::diag ("  (planepath_object ",ref $seq->{'planepath_object'},")");
          $bad++;
        }
      }
    }
    ok ($bad, 0);
  }
}


#------------------------------------------------------------------------------

sub is_nan {
  my ($x) = @_;
  return !($x==$x);
}

exit 0;
