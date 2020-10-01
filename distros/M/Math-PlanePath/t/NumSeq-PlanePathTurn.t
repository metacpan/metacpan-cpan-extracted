#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2019, 2020 Kevin Ryde

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

# uncomment this to run the ### lines
#use Smart::Comments '###';


my $test_count = (tests => 80)[1];
plan tests => $test_count;

if (! eval { require Math::NumSeq; 1 }) {
  MyTestHelpers::diag ('skip due to Math::NumSeq not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('due to no Math::NumSeq', 1, 1);
  }
  exit 0;
}

require Math::NumSeq::PlanePathTurn;


#------------------------------------------------------------------------------
# _turn_func_TTurn3()

# ok (Math::NumSeq::PlanePathTurn::_turn_func_TTurn3(2,0, 1,1),  .5,
#     'turn +60');
# ok (Math::NumSeq::PlanePathTurn::_turn_func_TTurn3(2,0, -1,1), 1,
#     'turn +120');
# ok (Math::NumSeq::PlanePathTurn::_turn_func_TTurn3(2,0, -1,-1), 2,
#     'turn +240');


#------------------------------------------------------------------------------
# _turn_func_Left()

ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(1,0, 0,1),  1,
    'left 90 from X axis');
ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(1,0, -5,5),  1,
    'left 135 from X axis');
ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(1,0, 1,0),  0,
    'straight along X axis');

ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(0,1, -1,0), 1,
    'left 90 from Y axis');
ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(0,1, -2,2), 1,
    'left 45 from Y axis');
ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(0,1, -4,-4), 1,
    'left 135 from Y axis');
ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(0,1, 0,1),  0,
    'straight along Y axis');

ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(-1,0, 0,-1),  1,
    'left 90 from X neg axis');
ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(-1,0, -1,0),  0,
    'straight along X neg axis');

ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(0,-1, 1,0), 1,
    'left 90 from Y neg axis');
ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(0,-1, 1,-1), 1,
    'left 45 from Y neg axis');
ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(0,-1, 1,1), 1,
    'left 135 from Y neg axis');
ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(0,-1, -1,-1), 0,
    'right 45 from Y neg axis');
ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(0,-1, -1,1), 0,
    'right 135 from Y neg axis');
ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(0,-1, 0,-1),  0,
    'straight along Y neg axis');

ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(1,0, 0,-1), 0,
    'right 90 from X axis');
ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(1,0, -1,0), 0); # straight opposite 180
ok (Math::NumSeq::PlanePathTurn::_turn_func_Left(0,1, 0,-1), 0); # straight opposite 180


#------------------------------------------------------------------------------
# _turn_func_Right()

ok (Math::NumSeq::PlanePathTurn::_turn_func_Right(1,0, 0,1),  0); # left 90
ok (Math::NumSeq::PlanePathTurn::_turn_func_Right(1,0, 1,0),  0); # straight
ok (Math::NumSeq::PlanePathTurn::_turn_func_Right(1,0, 0,-1), 1); # right 90
ok (Math::NumSeq::PlanePathTurn::_turn_func_Right(1,0, -1,0), 0); # straight opposite 180
ok (Math::NumSeq::PlanePathTurn::_turn_func_Right(0,1, 0,-1), 0); # straight opposite 180


#------------------------------------------------------------------------------
# _turn_func_LSR()

ok (Math::NumSeq::PlanePathTurn::_turn_func_LSR(1,0, 1,0),   0); # straight
ok (Math::NumSeq::PlanePathTurn::_turn_func_LSR(1,0, 0,1),   1); # left 90
ok (Math::NumSeq::PlanePathTurn::_turn_func_LSR(1,0, 0,-1), -1); # right 90
ok (Math::NumSeq::PlanePathTurn::_turn_func_LSR(1,0, -1,0),  0); # straight opposite 180
ok (Math::NumSeq::PlanePathTurn::_turn_func_LSR(0,1, 0,-1),  0); # straight opposite 180

#------------------------------------------------------------------------------
# values_min(), values_max()

foreach my $elem
  ([0,1, planepath => 'SquareSpiral' ], # default turn_type=>Left
   [0,1, planepath => 'SquareSpiral', turn_type => 'LSR' ],

   [0,1,  planepath => 'HilbertCurve', turn_type => 'Left' ],
   [-1,1, planepath => 'HilbertCurve', turn_type => 'LSR' ],

   [0,1,  planepath => 'CellularRule54', turn_type => 'Left' ],
   [-1,1, planepath => 'CellularRule54', turn_type => 'LSR' ],

   [0,1,  planepath => 'CellularRule190', turn_type => 'Left' ],
   [-1,1, planepath => 'CellularRule190', turn_type => 'LSR' ],

   [0,1,  planepath => 'Rows,width=6', turn_type => 'Left' ],
   [-1,1, planepath => 'Rows,width=6', turn_type => 'LSR' ],
   [0,1,  planepath => 'Columns,height=6', turn_type => 'Left' ],
   [-1,1, planepath => 'Columns,height=6', turn_type => 'LSR' ],

   # step=0 vertical on Y axis only
   [0,0, planepath=>'PyramidRows,step=0', turn_type => 'Left' ],
   [0,0, planepath=>'PyramidRows,step=0', turn_type => 'LSR' ],

   [0,1,  planepath=>'PyramidRows,step=1', turn_type => 'Left' ],
   [-1,1, planepath=>'PyramidRows,step=1', turn_type => 'LSR' ],

   # right line
   [0,0, planepath=>'CellularRule,rule=16', turn_type=>'Left' ],
   [0,0, planepath=>'CellularRule,rule=16', turn_type=>'LSR' ],

   # centre line Y axis only
   [0,0, planepath=>'CellularRule,rule=4', turn_type => 'Left' ],
   [0,0, planepath=>'CellularRule,rule=4', turn_type => 'LSR' ],

   # left line
   [0,0, planepath=>'CellularRule,rule=2', turn_type=>'Left' ],
   [0,0, planepath=>'CellularRule,rule=2', turn_type=>'LSR' ],

   # left solid
   [0,1,  planepath=>'CellularRule,rule=206', turn_type=>'Left' ],
   [-1,1, planepath=>'CellularRule,rule=206', turn_type=>'LSR' ],

   # odd solid
   [0,1,  planepath=>'CellularRule,rule=50',turn_type=>'Left' ],
   [-1,1, planepath=>'CellularRule,rule=50',turn_type=>'LSR' ],
  ) {
  my ($want_min,$want_max, @parameters) = @$elem;
  ### @parameters
  ### $want_min
  ### $want_max

  my $seq = Math::NumSeq::PlanePathTurn->new (@parameters);
  ok ($seq->values_min, $want_min,
      "values_min() ".join(',',@parameters));
  ok ($seq->values_max, $want_max,
      "values_max() ".join(',',@parameters));
}


#------------------------------------------------------------------------------
exit 0;
