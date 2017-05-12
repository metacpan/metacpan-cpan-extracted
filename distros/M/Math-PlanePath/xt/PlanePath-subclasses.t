#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


# Exercise the various PlanePath subclasses checking for consistency between
# n_to_xy() and xy_to_n() and the various range methods, etc.
#


use 5.004;
use strict;
use List::Util;
use Test;
plan tests => 5;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
# use Smart::Comments;


use Math::PlanePath;
use Math::PlanePath::Base::Generic
  'is_infinite';
use Math::PlanePath::Base::Digits
  'round_down_pow';

my $verbose = 1;

my @modules = (
               # modules marked "*" are from Math-PlanePath-Toothpick or
               # elsewhere and are skipped if not available to test

               # module list begin

               'GrayCode',
               'GrayCode,radix=3',
               'GrayCode,radix=4',
               'GrayCode,radix=5',
               'GrayCode,radix=6',
               'GrayCode,radix=37',
               'GrayCode,apply_type=FsT',
               'GrayCode,apply_type=FsT,radix=10',
               'GrayCode,apply_type=Fs',
               'GrayCode,apply_type=Fs,radix=10',
               'GrayCode,apply_type=Ts',
               'GrayCode,apply_type=Ts,radix=10',
               'GrayCode,apply_type=sF',
               'GrayCode,apply_type=sF,radix=10',
               'GrayCode,apply_type=sT',
               'GrayCode,apply_type=sT,radix=10',
               'GrayCode,radix=4,gray_type=modular',

               'CfracDigits,radix=1',
               'CfracDigits',
               'CfracDigits,radix=3',
               'CfracDigits,radix=4',
               'CfracDigits,radix=10',
               'CfracDigits,radix=37',

               'DigitGroups',
               'DigitGroups,radix=3',
               'DigitGroups,radix=4',
               'DigitGroups,radix=5',
               'DigitGroups,radix=37',

               'ChanTree',
               'ChanTree,n_start=1234',
               'ChanTree,k=2',
               'ChanTree,k=2,n_start=1234',
               'ChanTree,k=3',
               'ChanTree,k=4',
               'ChanTree,k=5',
               'ChanTree,k=6',
               'ChanTree,k=7',
               'ChanTree,k=8',
               'ChanTree,reduced=1',
               'ChanTree,reduced=1,k=2',
               'ChanTree,reduced=1,k=3',
               'ChanTree,reduced=1,k=4',
               'ChanTree,reduced=1,k=5',
               'ChanTree,reduced=1,k=6',
               'ChanTree,reduced=1,k=7',
               'ChanTree,reduced=1,k=8',

               'ImaginaryHalf',
               'ImaginaryHalf,radix=3',
               'ImaginaryHalf,radix=4',
               'ImaginaryHalf,radix=5',
               'ImaginaryHalf,radix=37',
               'ImaginaryHalf,digit_order=XXY,radix=3',
               'ImaginaryHalf,digit_order=YXX,radix=3',
               'ImaginaryHalf,digit_order=XnXY,radix=3',
               'ImaginaryHalf,digit_order=XnYX,radix=3',
               'ImaginaryHalf,digit_order=YXnX,radix=3',
               'ImaginaryHalf,digit_order=XXY,radix=3',

               'MultipleRings,ring_shape=polygon,step=3',
               'MultipleRings,ring_shape=polygon,step=4',
               'MultipleRings,ring_shape=polygon,step=5',
               'MultipleRings,ring_shape=polygon,step=6',
               'MultipleRings,ring_shape=polygon,step=7',
               'MultipleRings,ring_shape=polygon,step=8',
               'MultipleRings,ring_shape=polygon,step=9',
               'MultipleRings,ring_shape=polygon,step=12',
               'MultipleRings,ring_shape=polygon,step=37',
               'MultipleRings',
               'MultipleRings,step=0',
               'MultipleRings,step=1',
               'MultipleRings,step=2',
               'MultipleRings,step=3',
               'MultipleRings,step=4',
               'MultipleRings,step=5',
               'MultipleRings,step=6',
               'MultipleRings,step=7',
               'MultipleRings,step=8',
               'MultipleRings,step=37',

               'FilledRings',
               'FilledRings,n_start=0',
               'FilledRings,n_start=37',

               'Corner,n_start=101',
               'Corner,wider=1,n_start=101',
               'Corner,wider=2,n_start=37',
               'Corner,wider=13,n_start=37',
               'Corner',
               'Corner,wider=1',
               'Corner,wider=2',
               'Corner,wider=37',
               'Corner,n_start=0',
               'Corner,wider=1,n_start=0',
               'Corner,wider=2,n_start=0',
               'Corner,wider=37,n_start=0',

               'HexSpiral',
               'HexSpiral,n_start=0',
               'HexSpiral,n_start=37',
               'HexSpiral,wider=10,n_start=37',
               'HexSpiral,wider=1',
               'HexSpiral,wider=2',
               'HexSpiral,wider=3',
               'HexSpiral,wider=4',
               'HexSpiral,wider=5',
               'HexSpiral,wider=37',

               'HexSpiralSkewed',
               'HexSpiralSkewed,n_start=0',
               'HexSpiralSkewed,n_start=37',
               'HexSpiralSkewed,wider=10,n_start=37',
               'HexSpiralSkewed,wider=1',
               'HexSpiralSkewed,wider=2',
               'HexSpiralSkewed,wider=3',
               'HexSpiralSkewed,wider=4',
               'HexSpiralSkewed,wider=5',
               'HexSpiralSkewed,wider=37',

               'Columns',
               'Columns,height=1',
               'Columns,height=2',
               'Columns,n_start=0',
               'Columns,height=37,n_start=0',
               'Columns,height=37,n_start=123',
               'Rows',
               'Rows,width=1',
               'Rows,width=2',
               'Rows,n_start=0',
               'Rows,width=37,n_start=0',
               'Rows,width=37,n_start=123',

               'PeanoCurve',
               'PeanoCurve,radix=2',
               'PeanoCurve,radix=4',
               'PeanoCurve,radix=5',
               'PeanoCurve,radix=17',

               'PixelRings',

               'ImaginaryBase',
               'ImaginaryBase,radix=3',
               'ImaginaryBase,radix=4',
               'ImaginaryBase,radix=5',
               'ImaginaryBase,radix=37',

               'TriangularHypot',
               'TriangularHypot,n_start=0',
               'TriangularHypot,n_start=37',
               'TriangularHypot,points=odd',
               'TriangularHypot,points=all',
               'TriangularHypot,points=hex',
               'TriangularHypot,points=hex_rotated',
               'TriangularHypot,points=hex_centred',

               'GreekKeySpiral,turns=0,n_start=100',
               'GreekKeySpiral,turns=1,n_start=100',
               'GreekKeySpiral,turns=2,n_start=100',
               'GreekKeySpiral,turns=3,n_start=100',
               'GreekKeySpiral,turns=4,n_start=100',
               'GreekKeySpiral,turns=5,n_start=100',
               'GreekKeySpiral,turns=6,n_start=100',
               'GreekKeySpiral,turns=7,n_start=100',
               'GreekKeySpiral,turns=8,n_start=100',
               'GreekKeySpiral,turns=9,n_start=100',
               'GreekKeySpiral,turns=10,n_start=100',
               'GreekKeySpiral,turns=11,n_start=100',
               'GreekKeySpiral,turns=37,n_start=100',

               'SquareSpiral,n_start=0',
               'SquareSpiral,n_start=37',
               'SquareSpiral,wider=5,n_start=0',
               'SquareSpiral,wider=5,n_start=37',
               'SquareSpiral,wider=6,n_start=0',
               'SquareSpiral,wider=6,n_start=37',
               'SquareSpiral',
               'SquareSpiral,wider=1',
               'SquareSpiral,wider=2',
               'SquareSpiral,wider=3',
               'SquareSpiral,wider=4',
               'SquareSpiral,wider=5',
               'SquareSpiral,wider=6',
               'SquareSpiral,wider=37',

               'TerdragonMidpoint',
               'TerdragonMidpoint,arms=2',
               'TerdragonMidpoint,arms=3',
               'TerdragonMidpoint,arms=4',
               'TerdragonMidpoint,arms=5',
               'TerdragonMidpoint,arms=6',

               'AnvilSpiral,n_start=0',
               'AnvilSpiral,n_start=37',
               'AnvilSpiral,n_start=37,wider=9',
               'AnvilSpiral',
               'AnvilSpiral,wider=1',
               'AnvilSpiral,wider=2',
               'AnvilSpiral,wider=9',
               'AnvilSpiral,wider=17',

               'UlamWarburton',
               'UlamWarburton,parts=1',
               'UlamWarburton,parts=2',
               'UlamWarburton,parts=octant',
               'UlamWarburton,parts=octant_up',
               'UlamWarburton,n_start=0',
               'UlamWarburton,n_start=0,parts=2',
               'UlamWarburton,n_start=0,parts=1',
               'UlamWarburton,n_start=37',
               'UlamWarburton,n_start=37,parts=2',
               'UlamWarburton,n_start=37,parts=1',
               'UlamWarburtonQuarter,parts=octant',
               'UlamWarburtonQuarter,parts=octant,n_start=37',
               'UlamWarburtonQuarter,parts=octant_up',
               'UlamWarburtonQuarter,parts=octant_up,n_start=37',
               'UlamWarburtonQuarter',
               'UlamWarburtonQuarter,n_start=0',
               'UlamWarburtonQuarter,n_start=37',

               '*LCornerTree', # parts=4
               '*LCornerTree,parts=1',
               '*LCornerTree,parts=2',
               '*LCornerTree,parts=3',
               '*LCornerTree,parts=octant_up+1',
               '*LCornerTree,parts=octant+1',
               '*LCornerTree,parts=wedge+1',
               '*LCornerTree,parts=diagonal-1',
               '*LCornerTree,parts=diagonal',
               '*LCornerTree,parts=wedge',
               '*LCornerTree,parts=octant_up',
               '*LCornerTree,parts=octant',

               '*OneOfEight',
               '*OneOfEight,parts=1',
               '*OneOfEight,parts=octant',
               '*OneOfEight,parts=octant_up',
               '*OneOfEight,parts=wedge',
               '*OneOfEight,parts=3side',
               # '*OneOfEight,parts=side',
               '*OneOfEight,parts=3mid',

               'QuintetCentres',
               'QuintetCentres,arms=2',
               'QuintetCentres,arms=3',
               'QuintetCentres,arms=4',
               'QuintetReplicate',
               'QuintetCurve',
               'QuintetCurve,arms=2',
               'QuintetCurve,arms=3',
               'QuintetCurve,arms=4',

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
               'PythagoreanTree,tree_type=UMT',
               'PythagoreanTree,tree_type=UMT,coordinates=AC',
               'PythagoreanTree,tree_type=UMT,coordinates=BC',
               'PythagoreanTree,tree_type=UMT,coordinates=PQ',
               'PythagoreanTree,tree_type=UMT,coordinates=SM',
               'PythagoreanTree,tree_type=UMT,coordinates=SC',
               'PythagoreanTree,tree_type=UMT,coordinates=MC',

               'SierpinskiArrowhead',
               'SierpinskiArrowhead,align=right',
               'SierpinskiArrowhead,align=left',
               'SierpinskiArrowhead,align=diagonal',
               'SierpinskiArrowheadCentres',
               'SierpinskiArrowheadCentres,align=right',
               'SierpinskiArrowheadCentres,align=left',
               'SierpinskiArrowheadCentres,align=diagonal',

               'SierpinskiTriangle',
               'SierpinskiTriangle,n_start=37',
               'SierpinskiTriangle,align=left',
               'SierpinskiTriangle,align=right',
               'SierpinskiTriangle,align=diagonal',

               'HilbertSides',
               'HilbertCurve',
               'HilbertSpiral',

               '*ToothpickTree',
               '*ToothpickTree,parts=1',
               '*ToothpickTree,parts=2',
               '*ToothpickTree,parts=3',
               '*ToothpickTree,parts=wedge',
               '*ToothpickTree,parts=two_horiz',
               '*ToothpickTree,parts=octant',
               '*ToothpickTree,parts=octant_up',

               '*ToothpickReplicate',
               '*ToothpickReplicate,parts=1',
               '*ToothpickReplicate,parts=2',
               '*ToothpickReplicate,parts=3',

               '*HTree',
               '*LCornerReplicate',

               '*ToothpickUpist',

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
               'HIndexing',

               'KochSquareflakes',
               'KochSquareflakes,inward=>1',
               'KochCurve',
               'KochPeaks',
               'KochSnowflakes',

               'CCurve',

               'SierpinskiCurve',
               'SierpinskiCurve,arms=2',
               'SierpinskiCurve,arms=3',
               'SierpinskiCurve,arms=4',
               'SierpinskiCurve,arms=5',
               'SierpinskiCurve,arms=6',
               'SierpinskiCurve,arms=7',
               'SierpinskiCurve,arms=8',
               'SierpinskiCurve,diagonal_spacing=5',
               'SierpinskiCurve,straight_spacing=5',
               'SierpinskiCurve,diagonal_spacing=3,straight_spacing=7',
               'SierpinskiCurve,diagonal_spacing=3,straight_spacing=7,arms=7',

               'R5DragonMidpoint',
               'R5DragonMidpoint,arms=2',
               'R5DragonMidpoint,arms=3',
               'R5DragonMidpoint,arms=4',

               'R5DragonCurve',
               'R5DragonCurve,arms=2',
               'R5DragonCurve,arms=3',
               'R5DragonCurve,arms=4',

               'QuadricCurve',
               'QuadricIslands',

               'LTiling',
               'LTiling,L_fill=ends',
               'LTiling,L_fill=all',
               'FibonacciWordFractal',

               'ComplexRevolving',
               'ComplexPlus',
               'ComplexPlus,realpart=2',
               'ComplexPlus,realpart=3',
               'ComplexPlus,realpart=4',
               'ComplexPlus,realpart=5',
               'ComplexMinus',
               'ComplexMinus,realpart=2',
               'ComplexMinus,realpart=3',
               'ComplexMinus,realpart=4',
               'ComplexMinus,realpart=5',

               'GosperReplicate',
               'GosperSide',

               'SquareReplicate',

               'DekkingCurve',
               'DekkingCurve,arms=2',
               'DekkingCurve,arms=3',
               'DekkingCurve,arms=4',
               'DekkingCentres',

               'DragonMidpoint',
               'DragonMidpoint,arms=2',
               'DragonMidpoint,arms=3',
               'DragonMidpoint,arms=4',

               'DragonRounded',
               'DragonRounded,arms=2',
               'DragonRounded,arms=3',
               'DragonRounded,arms=4',

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

               'DragonCurve',
               'DragonCurve,arms=2',
               'DragonCurve,arms=3',
               'DragonCurve,arms=4',

               'ZOrderCurve',
               'ZOrderCurve,radix=3',
               'ZOrderCurve,radix=5',
               'ZOrderCurve,radix=9',
               'ZOrderCurve,radix=37',

               'Flowsnake',
               'Flowsnake,arms=2',
               'Flowsnake,arms=3',
               'FlowsnakeCentres',
               'FlowsnakeCentres,arms=2',
               'FlowsnakeCentres,arms=3',

               'AlternatePaper',
               'AlternatePaper,arms=2',
               'AlternatePaper,arms=3',
               'AlternatePaper,arms=4',
               'AlternatePaper,arms=5',
               'AlternatePaper,arms=6',
               'AlternatePaper,arms=7',
               'AlternatePaper,arms=8',

               'CellularRule,rule=18',  # Sierpinski
               'CellularRule,rule=18,n_start=0',
               'CellularRule,rule=18,n_start=37',

               'CubicBase',
               'CubicBase,radix=3',
               'CubicBase,radix=4',
               'CubicBase,radix=37',

               'GosperIslands',

               'PowerArray',
               'PowerArray,radix=3',
               'PowerArray,radix=4',

               'WythoffPreliminaryTriangle',

               'WythoffArray',
               'WythoffArray,x_start=1',
               'WythoffArray,y_start=1',
               'WythoffArray,x_start=1,y_start=1',
               'WythoffArray,x_start=5,y_start=7',

               'DiagonalsAlternating',
               'DiagonalsAlternating,n_start=0',
               'DiagonalsAlternating,n_start=37',
               'DiagonalsAlternating,x_start=5',
               'DiagonalsAlternating,x_start=2,y_start=5',

               # Math::PlanePath::CellularRule::Line
               'CellularRule,rule=2',  # left line
               'CellularRule,rule=2,n_start=0',
               'CellularRule,rule=2,n_start=37',
               'CellularRule,rule=4',  # centre line
               'CellularRule,rule=4,n_start=0',
               'CellularRule,rule=4,n_start=37',
               'CellularRule,rule=16', # right line
               'CellularRule,rule=16,n_start=0',
               'CellularRule,rule=16,n_start=37',

               'CellularRule,rule=6',   # left 1,2 line
               'CellularRule,rule=6,n_start=0',
               'CellularRule,rule=6,n_start=37',
               'CellularRule,rule=20',  # right 1,2 line
               'CellularRule,rule=20,n_start=0',
               'CellularRule,rule=20,n_start=37',

               # Math::PlanePath::CellularRule::Two
               'CellularRule,rule=14',  # left 2 cell line
               'CellularRule,rule=14,n_start=0',
               'CellularRule,rule=14,n_start=37',
               'CellularRule,rule=84',  # right 2 cell line
               'CellularRule,rule=84,n_start=0',
               'CellularRule,rule=84,n_start=37',

               'CellularRule',
               'CellularRule,n_start=0',
               'CellularRule,n_start=37',

               'CellularRule,rule=206', # left solid
               'CellularRule,rule=206,n_start=0',
               'CellularRule,rule=206,n_start=37',

               'CellularRule,rule=0',   # blank
               'CellularRule,rule=60',
               'CellularRule,rule=220', # right half solid
               'CellularRule,rule=222', # full solid

               'CretanLabyrinth',

               'MPeaks',
               'MPeaks,n_start=0',
               'MPeaks,n_start=37',

               '*ToothpickSpiral',
               '*ToothpickSpiral,n_start=0',
               '*ToothpickSpiral,n_start=37',

               'WunderlichSerpentine',
               'WunderlichSerpentine,serpentine_type=100_000_00000',
               'WunderlichSerpentine,serpentine_type=110_000_00000',
               'WunderlichSerpentine,serpentine_type=111_000_00000',
               'WunderlichSerpentine,serpentine_type=10000_00000_00000,radix=5',
               'WunderlichSerpentine,serpentine_type=11000_00000_00000,radix=5',
               'WunderlichSerpentine,serpentine_type=11100_00000_00000,radix=5',
               'WunderlichSerpentine,serpentine_type=11110_00000_00000,radix=5',
               'WunderlichSerpentine,serpentine_type=11111_00000_00000,radix=5',
               'WunderlichSerpentine,serpentine_type=11111_10000_00000,radix=5',
               'WunderlichSerpentine,serpentine_type=11111_11000_00000,radix=5',
               'WunderlichSerpentine,serpentine_type=000_000_001',
               'WunderlichSerpentine,serpentine_type=010_000_001',
               'WunderlichSerpentine,serpentine_type=001_000_001',
               'WunderlichSerpentine,serpentine_type=000_100_001',
               'WunderlichSerpentine,serpentine_type=000_000_001,radix=5',
               'WunderlichSerpentine,serpentine_type=010_000_001,radix=5',
               'WunderlichSerpentine,serpentine_type=001_000_001,radix=5',
               'WunderlichSerpentine,serpentine_type=000_100_001,radix=5',
               'WunderlichSerpentine,radix=2',
               'WunderlichSerpentine,radix=4',
               'WunderlichSerpentine,radix=5,serpentine_type=coil', # 111..111

               'VogelFloret',
               'ArchimedeanChords',
               'TheodorusSpiral',
               'SacksSpiral',

               'Hypot,n_start=37',
               'Hypot,points=even,n_start=37',
               'Hypot',
               'Hypot,points=even',
               'Hypot,points=odd',
               'HypotOctant',
               'HypotOctant,points=even',
               'HypotOctant,points=odd',

               'PyramidRows,align=right',
               'PyramidRows,align=right,step=0',
               'PyramidRows,align=right,step=1',
               'PyramidRows,align=right,step=3',
               'PyramidRows,align=right,step=4',
               'PyramidRows,align=right,step=5',
               'PyramidRows,align=right,step=37',
               'PyramidRows,align=left',
               'PyramidRows,align=left,step=0',
               'PyramidRows,align=left,step=1',
               'PyramidRows,align=left,step=3',
               'PyramidRows,align=left,step=4',
               'PyramidRows,align=left,step=5',
               'PyramidRows,align=left,step=37',
               'PyramidRows',
               'PyramidRows,step=0',
               'PyramidRows,step=1',
               'PyramidRows,step=3',
               'PyramidRows,step=4',
               'PyramidRows,step=5',
               'PyramidRows,step=37',
               'PyramidRows,step=0,n_start=37',
               'PyramidRows,step=1,n_start=37',
               'PyramidRows,step=2,n_start=37',
               'PyramidRows,align=right,step=5,n_start=37',
               'PyramidRows,align=left,step=3,n_start=37',

               'TriangleSpiralSkewed',
               'TriangleSpiralSkewed,n_start=0',
               'TriangleSpiralSkewed,n_start=37',
               'TriangleSpiralSkewed,skew=right',
               'TriangleSpiralSkewed,skew=right,n_start=0',
               'TriangleSpiralSkewed,skew=right,n_start=37',
               'TriangleSpiralSkewed,skew=up',
               'TriangleSpiralSkewed,skew=up,n_start=0',
               'TriangleSpiralSkewed,skew=up,n_start=37',
               'TriangleSpiralSkewed,skew=down',
               'TriangleSpiralSkewed,skew=down,n_start=0',
               'TriangleSpiralSkewed,skew=down,n_start=37',

               'TriangleSpiral',
               'TriangleSpiral,n_start=0',
               'TriangleSpiral,n_start=37',

               'KnightSpiral',
               'KnightSpiral,n_start=0',
               'KnightSpiral,n_start=37',

               'AlternatePaperMidpoint',
               'AlternatePaperMidpoint,arms=2',
               'AlternatePaperMidpoint,arms=3',
               'AlternatePaperMidpoint,arms=4',
               'AlternatePaperMidpoint,arms=5',
               'AlternatePaperMidpoint,arms=6',
               'AlternatePaperMidpoint,arms=7',
               'AlternatePaperMidpoint,arms=8',

               'PentSpiral',
               'PentSpiral,n_start=0',
               'PentSpiral,n_start=37',
               'PentSpiralSkewed',
               'PentSpiralSkewed,n_start=0',
               'PentSpiralSkewed,n_start=37',

               'CellularRule54',
               'CellularRule54,n_start=0',
               'CellularRule54,n_start=37',

               'CellularRule57',
               'CellularRule57,n_start=0',
               'CellularRule57,n_start=37',
               'CellularRule57,mirror=1',
               'CellularRule57,mirror=1,n_start=0',
               'CellularRule57,mirror=1,n_start=37',

               'CellularRule190',
               'CellularRule190,n_start=0',
               'CellularRule190,n_start=37',
               'CellularRule190,mirror=1',
               'CellularRule190,mirror=1,n_start=0',
               'CellularRule190,mirror=1,n_start=37',

               'DivisibleColumns',
               'DivisibleColumns,n_start=37',
               'DivisibleColumns,divisor_type=proper',
               'CoprimeColumns',
               'CoprimeColumns,n_start=37',

               'DiamondArms',
               'SquareArms',
               'HexArms',

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

               'AztecDiamondRings',
               'AztecDiamondRings,n_start=0',
               'AztecDiamondRings,n_start=37',

               'FactorRationals,sign_encoding=revbinary',
               'FactorRationals',
               'FactorRationals,sign_encoding=odd/even',
               'FactorRationals,sign_encoding=negabinary',
               'FactorRationals,sign_encoding=spread',

               'PyramidSides',
               'PyramidSides,n_start=0',
               'PyramidSides,n_start=37',

               'Diagonals',
               'Diagonals,direction=up',
               'Diagonals,n_start=0',
               'Diagonals,direction=up,n_start=0',
               'Diagonals,n_start=37',
               'Diagonals,direction=up,n_start=37',
               'Diagonals,x_start=5',
               'Diagonals,direction=up,x_start=5',
               'Diagonals,x_start=2,y_start=5',
               'Diagonals,direction=up,x_start=2,y_start=5',

               'PyramidSpiral',
               'PyramidSpiral,n_start=0',
               'PyramidSpiral,n_start=37',

               'HeptSpiralSkewed',
               'HeptSpiralSkewed,n_start=0',
               'HeptSpiralSkewed,n_start=37',

               'Staircase',
               'Staircase,n_start=0',
               'Staircase,n_start=37',
               'StaircaseAlternating',
               'StaircaseAlternating,n_start=0',
               'StaircaseAlternating,n_start=37',
               'StaircaseAlternating,end_type=square',
               'StaircaseAlternating,end_type=square,n_start=0',
               'StaircaseAlternating,end_type=square,n_start=37',

               'OctagramSpiral',
               'OctagramSpiral,n_start=0',
               'OctagramSpiral,n_start=37',

               'CornerReplicate',

               'RationalsTree',
               'RationalsTree,tree_type=CW',
               'RationalsTree,tree_type=AYT',
               'RationalsTree,tree_type=Bird',
               'RationalsTree,tree_type=Drib',
               'RationalsTree,tree_type=L',
               'RationalsTree,tree_type=HCS',

               # '*PeninsulaBridge',

               'DiagonalRationals',
               'DiagonalRationals,n_start=37',
               'DiagonalRationals,direction=up',
               'DiagonalRationals,direction=up,n_start=37',

               'GcdRationals',
               'GcdRationals,pairs_order=rows_reverse',
               'GcdRationals,pairs_order=diagonals_down',
               'GcdRationals,pairs_order=diagonals_up',

               'DiamondSpiral',
               'DiamondSpiral,n_start=0',
               'DiamondSpiral,n_start=37',

               'FractionsTree',

               'DiagonalsOctant',
               'DiagonalsOctant,direction=up',
               'DiagonalsOctant,n_start=0',
               'DiagonalsOctant,direction=up,n_start=0',
               'DiagonalsOctant,n_start=37',
               'DiagonalsOctant,direction=up,n_start=37',

               'File',

               # module list end

               # cellular 0 to 255
               (map {("CellularRule,rule=$_",
                      "CellularRule,rule=$_,n_start=0",
                      "CellularRule,rule=$_,n_start=37")} 0..255),
              );

@modules = grep { module_exists($_) } @modules;
sub module_exists {
  my ($module) = @_;
  if ($module =~ /^\*([^,]+)/) {
    require Module::Util;
    my $filename = Module::Util::find_installed("Math::PlanePath::$1");
    if ($filename) {
      return 1;
    } else {
      MyTestHelpers::diag ("skip optional $module");
      return 0;
    }
  } else {
    return 1;  # not optional
  }
}
foreach (@modules) { s/^\*// }

my @classes = map {(module_parse($_))[0]} @modules;
{ my %seen; @classes = grep {!$seen{$_}++} @classes } # uniq

sub module_parse {
  my ($mod) = @_;
  my ($class, @parameters) = split /,/, $mod;
  return ("Math::PlanePath::$class",
          map {/(.*?)=(.*)/ or die; ($1 => $2)} @parameters);
}
sub module_to_pathobj {
  my ($mod) = @_;
  my ($class, @parameters) = module_parse($mod);
  ### $mod
  ### @parameters
  eval "require $class" or die;
  return $class->new (@parameters);
}

{
  eval {
    require Module::Util;
    my %classes = map {$_=>1} @classes;
    foreach my $module (Module::Util::find_in_namespace('Math::PlanePath')) {
      next if $classes{$module};  # listed, good
      next if $module =~ /^Math::PlanePath::[^:]+::/; # skip Base etc submods
      MyTestHelpers::diag ("other module ",$module);
    }
  };
}

BEGIN {
  my @dir4_to_dx = (1,0,-1,0);
  my @dir4_to_dy = (0,1,0,-1);

  # return the change in figure boundary from N to N+1
  sub path_n_to_dboundary {
    my ($path, $n) = @_;
    $n += 1;
    my ($x,$y) = $path->n_to_xy($n) or do {
      if ($n == $path->n_start - 1) {
        return 4;
      } else {
        return undef;
      }
    };
    ### N+1 at: "n=$n  xy=$x,$y"
    my $dboundary = 4;
    foreach my $i (0 .. $#dir4_to_dx) {
      my $an = $path->xy_to_n($x+$dir4_to_dx[$i], $y+$dir4_to_dy[$i]);
      ### consider: "xy=".($x+$dir4_to_dx[$i]).",".($y+$dir4_to_dy[$i])." is an=".($an||'false')
      $dboundary -= 2*(defined $an && $an < $n);
    }
    ### $dboundary
    return $dboundary;
  }
}

#------------------------------------------------------------------------------
# VERSION

my $want_version = 124;

ok ($Math::PlanePath::VERSION, $want_version, 'VERSION variable');
ok (Math::PlanePath->VERSION,  $want_version, 'VERSION class method');

ok (eval { Math::PlanePath->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { Math::PlanePath->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# new and VERSION

# foreach my $class (@classes) {
#   eval "require $class" or die;
#
#   ok (eval { $class->VERSION($want_version); 1 },
#       1,
#       "VERSION class check $want_version in $class");
#   ok (! eval { $class->VERSION($check_version); 1 },
#       1,
#       "VERSION class check $check_version in $class");
#
#   my $path = $class->new;
#   ok ($path->VERSION, $want_version,
#       "VERSION object method in $class");
#
#   ok (eval { $path->VERSION($want_version); 1 },
#       1,
#       "VERSION object check $want_version in $class");
#   ok (! eval { $path->VERSION($check_version); 1 },
#       1,
#       "VERSION object check $check_version in $class");
# }

#------------------------------------------------------------------------------
# x_negative, y_negative

foreach my $mod (@modules) {
  my $path = module_to_pathobj($mod);
  $path->x_negative;
  $path->y_negative;
  $path->n_start;
  # ok (1,1, 'x_negative(),y_negative(),n_start() methods run');
}

#------------------------------------------------------------------------------
# n_to_xy, xy_to_n

my %xy_maximum_duplication =
  ('Math::PlanePath::HilbertSides' => 2,
   'Math::PlanePath::DragonCurve' => 2,
   'Math::PlanePath::R5DragonCurve' => 2,
   'Math::PlanePath::CCurve' => 9999,
   'Math::PlanePath::AlternatePaper' => 2,
   'Math::PlanePath::TerdragonCurve' => 3,
   'Math::PlanePath::KochSnowflakes' => 2,
   'Math::PlanePath::QuadricIslands' => 2,
  );
my %xy_maximum_duplication_at_origin =
  ('Math::PlanePath::DragonCurve' => 4,
   'Math::PlanePath::TerdragonCurve' => 6,
   'Math::PlanePath::R5DragonCurve' => 4,
  );

# modules for which rect_to_n_range() is exact
my %rect_exact = (
                  # rect_to_n_range exact begin
                  'Math::PlanePath::ImaginaryBase' => 1,
                  'Math::PlanePath::CincoCurve' => 1,
                  'Math::PlanePath::DiagonalsAlternating' => 1,
                  'Math::PlanePath::CornerReplicate' => 1,
                  'Math::PlanePath::Rows' => 1,
                  'Math::PlanePath::Columns' => 1,
                  'Math::PlanePath::Diagonals' => 1,
                  'Math::PlanePath::DiagonalsOctant' => 1,
                  'Math::PlanePath::Staircase' => 1,
                  'Math::PlanePath::StaircaseAlternating' => 1,
                  'Math::PlanePath::PyramidRows' => 1,
                  'Math::PlanePath::PyramidSides' => 1,
                  'Math::PlanePath::CellularRule190' => 1,
                  'Math::PlanePath::Corner' => 1,
                  'Math::PlanePath::HilbertCurve' => 1,
                  'Math::PlanePath::HilbertSpiral' => 1,
                  'Math::PlanePath::PeanoCurve' => 1,
                  'Math::PlanePath::ZOrderCurve' => 1,
                  'Math::PlanePath::Flowsnake' => 1,
                  'Math::PlanePath::FlowsnakeCentres' => 1,
                  'Math::PlanePath::QuintetCurve' => 1,
                  'Math::PlanePath::QuintetCentres' => 1,
                  'Math::PlanePath::DiamondSpiral' => 1,
                  'Math::PlanePath::AztecDiamondRings' => 1,
                  'Math::PlanePath::BetaOmega' => 1,
                  'Math::PlanePath::AR2W2Curve' => 1,
                  'Math::PlanePath::KochelCurve' => 1,
                  'Math::PlanePath::WunderlichMeander' => 1,
                  'Math::PlanePath::File' => 1,
                  'Math::PlanePath::KochCurve' => 1,
                  # rect_to_n_range exact end
                 );
my %rect_exact_hi = (%rect_exact,
                     # high is exact but low is not
                     'Math::PlanePath::SquareSpiral' => 1,
                     'Math::PlanePath::SquareArms' => 1,
                     'Math::PlanePath::TriangleSpiralSkewed' => 1,
                     'Math::PlanePath::MPeaks' => 1,
                    );
my %rect_before_n_start = ('Math::PlanePath::Rows' => 1,
                           'Math::PlanePath::Columns' => 1,
                          );

my %non_linear_frac = (
                       'Math::PlanePath::SacksSpiral' => 1,
                       'Math::PlanePath::VogelFloret' => 1,
                      );


#------------------------------------------------------------------------------
my ($pos_infinity, $neg_infinity, $nan);
my ($is_infinity, $is_nan);
if (! eval { require Data::Float; 1 }) {
  MyTestHelpers::diag ("Data::Float not available");
} elsif (! Data::Float::have_infinite()) {
  MyTestHelpers::diag ("Data::Float have_infinite() is false");
} else {
  $is_infinity = sub {
    my ($x) = @_;
    return defined($x) && Data::Float::float_is_infinite($x);
  };
  $is_nan = sub {
    my ($x) = @_;
    return defined($x) && Data::Float::float_is_nan($x);
  };
  $pos_infinity = Data::Float::pos_infinity();
  $neg_infinity = Data::Float::neg_infinity();
  $nan = Data::Float::nan();
}
sub pos_infinity_maybe {
  return (defined $pos_infinity ? $pos_infinity : ());
}
sub neg_infinity_maybe {
  return (defined $neg_infinity ? $neg_infinity : ());
}

sub dbl_max {
  require POSIX;
  return POSIX::DBL_MAX();
}
sub dbl_max_neg {
  require POSIX;
  return - POSIX::DBL_MAX();
}
sub dbl_max_for_class_xy {
  my ($path) = @_;
  ### dbl_max_for_class_xy(): "$path"
  if ($path->isa('Math::PlanePath::CoprimeColumns')
      || $path->isa('Math::PlanePath::DiagonalRationals')
      || $path->isa('Math::PlanePath::DivisibleColumns')
      || $path->isa('Math::PlanePath::CellularRule')
      || $path->isa('Math::PlanePath::DragonCurve')
      || $path->isa('Math::PlanePath::PixelRings')
     ) {
    ### don't try DBL_MAX on this path xy_to_n() ...
    return ();
  }
  return dbl_max();
}
sub dbl_max_neg_for_class_xy {
  my ($path) = @_;
  if (dbl_max_for_class_xy($path)) {
    return dbl_max_neg();
  } else {
    return ();
  }
}
sub dbl_max_for_class_rect {
  my ($path) = @_;
  # no DBL_MAX on these
  if ($path->isa('Math::PlanePath::CoprimeColumns')
      || $path->isa('Math::PlanePath::DiagonalRationals')
      || $path->isa('Math::PlanePath::DivisibleColumns')
      || $path->isa('Math::PlanePath::CellularRule')
      || $path->isa('Math::PlanePath::PixelRings')
     ) {
    ### don't try DBL_MAX on this path rect_to_n_range() ...
    return ();
  }
  return dbl_max();
}
sub dbl_max_neg_for_class_rect {
  my ($path) = @_;
  if (dbl_max_for_class_rect($path)) {
    return dbl_max_neg();
  } else {
    return ();
  }
}

sub is_pos_infinity {
  my ($n) = @_;
  return defined $n && defined $pos_infinity && $n == $pos_infinity;
}
sub is_neg_infinity {
  my ($n) = @_;
  return defined $n && defined $neg_infinity && $n == $neg_infinity;
}

sub pythagorean_diag {
  my ($path,$x,$y) = @_;
  $path->isa('Math::PlanePath::PythagoreanTree')
    or return;

  my $z = Math::Libm::hypot ($x, $y);
  my $z_not_int = (int($z) != $z);
  my $z_even = ! ($z & 1);

  MyTestHelpers::diag ("x=$x y=$y, hypot z=$z z_not_int='$z_not_int' z_even='$z_even'");

  my $psq = ($z+$x)/2;
  my $p = sqrt(($z+$x)/2);
  my $p_not_int = ($p != int($p));
  MyTestHelpers::diag ("psq=$psq p=$p p_not_int='$p_not_int'");

  my $qsq = ($z-$x)/2;
  my $q = sqrt(($z-$x)/2);
  my $q_not_int = ($q != int($q));
  MyTestHelpers::diag ("qsq=$qsq q=$q q_not_int='$q_not_int'");
}

{
  my $default_limit = ($ENV{'MATH_PLANEPATH_TEST_LIMIT'} || 30);
  my $rect_limit = $ENV{'MATH_PLANEPATH_TEST_RECT_LIMIT'} || 4;
  MyTestHelpers::diag ("test limit $default_limit, rect limit $rect_limit");
  my $good = 1;
  
  foreach my $mod (@modules) {
    if ($verbose) {
      MyTestHelpers::diag ($mod);
    }
    
    my ($class, %parameters) = module_parse($mod);
    ### $class
    eval "require $class" or die;
    
    my $xy_maximum_duplication = $xy_maximum_duplication{$class} || 0;
    
    #
    # MyTestHelpers::diag ($mod);
    #
    
    my $depth_limit = 10;
    my $limit = $default_limit;
    if (defined (my $step = $parameters{'step'})) {
      if ($limit < 6*$step) {
        $limit = 6*$step; # so goes into x/y negative
      }
    }
    if ($mod =~ /^ArchimedeanChords/) {
      if ($limit > 1100) {
        $limit = 1100;  # bit slow otherwise
      }
    }
    if ($mod =~ /^CoprimeColumns|^DiagonalRationals/) {
      if ($limit > 1100) {
        $limit = 1100;  # bit slow otherwise
      }
    }
    
    my $report = sub {
      my $name = $mod;
      MyTestHelpers::diag ($name, ' oops ', @_);
      $good = 0;
      # exit 1;
    };
    
    my $path = $class->new (width  => 20,
                            height => 20,
                            %parameters);
    my $arms_count = $path->arms_count;
    my $n_start = $path->n_start;
    
    if ($mod !~ /,/) {
      # base class only
      
      my $parameter_info_hash = $path->parameter_info_hash;
      if (my $pinfo = $parameter_info_hash->{'n_start'}) {
        $pinfo->{'default'} == $n_start
          or &$report("parameter info n_start default $pinfo->{'default'} but path->n_start $n_start");
      }
      if (my $pinfo = $parameter_info_hash->{'arms'}) {
        $pinfo->{'default'} == $arms_count
          or &$report("parameter info arms_count default $pinfo->{'default'} but path->arms_count $arms_count");
      }
      
      foreach my $pinfo ($path->parameter_info_list) {
        if ($pinfo->{'type'} eq 'enum') {
          my $choices = $pinfo->{'choices'};
          my $num_choices = scalar(@$choices);
          if (my $choices_display = $pinfo->{'choices_display'}) {
            my $num_choices_display = scalar(@$choices_display);
            if ($num_choices != $num_choices_display) {
              &$report("parameter info $pinfo->{'name'} choices $num_choices but choices_display $num_choices_display");
            }
          }
        }
      }
      
      ### level_to_n_range() different among arms ...
      # This checks that if there's an arms parameter then the
      # level_to_n_range() code takes account of it.
      if (my $pinfo = $parameter_info_hash->{'arms'}) {
        my %seen;
        foreach my $arms ($pinfo->{'minimum'} .. $pinfo->{'maximum'}) {
          my $apath = $class->new (arms => $arms);
          my ($n_lo, $n_hi) = $apath->level_to_n_range(3)
            or next;
          if (exists $seen{$n_hi}) {
            &$report ("level_to_n_range() n_hi=$n_hi at arms=$arms is same as from arms=$seen{$n_hi}");
          } else {
            $seen{$n_hi} = $arms;
          }
        }
        ### %seen
      }
      
      ### level_to_n_range() follows n_start ...
      if (my $pinfo = $parameter_info_hash->{'n_start'}) {
        my $apath = $class->new (n_start => 100);
        my ($n_lo_100, $n_hi_100) = $path->level_to_n_range(3)
          or next;
        my $bpath = $class->new (n_start => 200);
        my ($n_lo_200, $n_hi_200) = $path->level_to_n_range(3)
          or next;
        if ($n_lo_100 + 100 == $n_lo_200
            && $n_hi_100 + 100 == $n_hi_200) {
          &$report ("level_to_n_range() not affected by n_start");
        }
      }
    }
    
    if ($parameters{'arms'} && $arms_count != $parameters{'arms'}) {
      &$report("arms_count()==$arms_count expect $parameters{'arms'}");
    }
    unless ($arms_count >= 1) {
      &$report("arms_count()==$arms_count should be >=1");
    }
    
    my $n_limit = $n_start + $limit;
    my $n_frac_discontinuity = $path->n_frac_discontinuity;
    
    my $x_negative_at_n = $path->x_negative_at_n;
    if (defined $x_negative_at_n) {
      $x_negative_at_n >= $n_start
        or &$report ("x_negative_at_n() = $x_negative_at_n is < n_start=$n_start");
    }
    my $y_negative_at_n = $path->y_negative_at_n;
    if (defined $y_negative_at_n) {
      $y_negative_at_n >= $n_start
        or &$report ("y_negative_at_n() = $y_negative_at_n is < n_start=$n_start");
    }
    
    # _UNDOCUMENTED__dxdy_list()
    #
    my @_UNDOCUMENTED__dxdy_list = $path->_UNDOCUMENTED__dxdy_list; # list ($dx,$dy, $dx,$dy, ...)
    @_UNDOCUMENTED__dxdy_list % 2 == 0
      or &$report ("_UNDOCUMENTED__dxdy_list() not an even number of values");
    my %_UNDOCUMENTED__dxdy_list;  # keys "$dx,$dy"
    for (my $i = 0; $i < $#_UNDOCUMENTED__dxdy_list; $i += 2) {
      $_UNDOCUMENTED__dxdy_list{"$_UNDOCUMENTED__dxdy_list[$i],$_UNDOCUMENTED__dxdy_list[$i+1]"} = 1;
    }
    for (my $i = 2; $i < $#_UNDOCUMENTED__dxdy_list; $i += 2) {
      if (dxdy_cmp ($_UNDOCUMENTED__dxdy_list[$i-2],$_UNDOCUMENTED__dxdy_list[$i-1],
                    $_UNDOCUMENTED__dxdy_list[$i],$_UNDOCUMENTED__dxdy_list[$i+1]) >= 0) {
        &$report ("_UNDOCUMENTED__dxdy_list() entries not sorted: $_UNDOCUMENTED__dxdy_list[$i-2],$_UNDOCUMENTED__dxdy_list[$i-1] then $_UNDOCUMENTED__dxdy_list[$i],$_UNDOCUMENTED__dxdy_list[$i+1]");
      }
    }
    
    {
      my ($x,$y) = $path->n_to_xy($n_start);
      if (! defined $x) {
        unless ($path->isa('Math::PlanePath::File')) {
          &$report("n_start()==$n_start doesn't have an n_to_xy()");
        }
      } else {
        my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
        if ($n_lo > $n_start || $n_hi < $n_start) {
          &$report("n_start()==$n_start outside rect_to_n_range() $n_lo..$n_hi");
        }
      }
    }
    
    if (# VogelFloret has a secret undocumented return for N=0
        ! $path->isa('Math::PlanePath::VogelFloret')
        # Rows/Columns secret undocumented extend into negatives ...
        && ! $path->isa('Math::PlanePath::Rows')
        && ! $path->isa('Math::PlanePath::Columns')) {
      my $n = $n_start - 1;
      {
        my @xy = $path->n_to_xy($n);
        if (scalar @xy) {
          &$report("n_to_xy() at n_start()-1=$n has X,Y but should not");
        }
      }
      foreach my $method ('n_to_rsquared', 'n_to_radius') {
        my @ret = $path->$method($n);
        if (scalar(@ret) != 1) {
          &$report("$method() at n_start()-1 return not one value");
        } elsif (defined $ret[0]) {
          &$report("$method() at n_start()-1 has defined value but should not");
        }
        foreach my $offset (1, 2, 123) {
          ### n_to_r (n_start - offset): $offset
          my $n = $n_start - $offset;
          my @ret = $path->$method($n);
          if ($path->isa('Math::PlanePath::File')) {
            @ret = (undef);  # all undefs for File
          }
          my $num_values = scalar(@ret);
          $num_values == 1
            or &$report("$method(n_start - $offset) got $num_values values, want 1");
          if ($path->isa('Math::PlanePath::Rows')
              || $path->isa('Math::PlanePath::Columns')) {
            ### Rows,Columns has secret values for negative N, pretend not ...
            @ret = (undef);
          }
          if ($offset == 1 && $path->isa('Math::PlanePath::VogelFloret')) {
            ### VogelFloret has a secret undocumented return for N=0 ...
            @ret = (undef);
          }
          my ($ret) = @ret;
          if (defined $ret) {
            &$report("$method($n) n_start-$offset is ",$ret," expected undef");
          }
        }
      }
    }
    
    {
      my $saw_warning;
      local $SIG{'__WARN__'} = sub { $saw_warning = 1; };
      foreach my $method ('n_to_xy','n_to_dxdy',
                          'n_to_rsquared',
                          'n_to_radius',
                          ($path->tree_n_num_children($n_start)
                           ? ('tree_n_to_depth',
                              'tree_depth_to_n',
                              'tree_depth_to_n_end',
                              'tree_depth_to_n_range',
                              'tree_n_parent',
                              'tree_n_root',
                              'tree_n_children',
                              'tree_n_num_children',
                             )
                           : ())){
        $saw_warning = 0;
        $path->$method(undef);
        $saw_warning or &$report("$method(undef) doesn't give a warning");
      }
      {
        $saw_warning = 0;
        $path->xy_to_n(0,undef);
        $saw_warning or &$report("xy_to_n(0,undef) doesn't give a warning");
      }
      {
        $saw_warning = 0;
        $path->xy_to_n(undef,0);
        $saw_warning or &$report("xy_to_n(undef,0) doesn't give a warning");
      }
      
      # No warning if xy_is_visited() is a constant, skip test in that case.
      unless (coderef_is_const($path->can('xy_is_visited'))) {
        $saw_warning = 0;
        $path->xy_is_visited(0,undef);
        $saw_warning or &$report("xy_is_visited(0,undef) doesn't give a warning");
        $saw_warning = 0;
        $path->xy_is_visited(undef,0);
        $saw_warning or &$report("xy_is_visited(undef,0) doesn't give a warning");
      }
    }
    
    # undef ok if nothing sensible
    # +/-inf ok
    # nan not intended, but might be ok
    # finite could be a fixed x==0
    if (defined $pos_infinity) {
      {
        ### n_to_xy($pos_infinity) ...
        my ($x, $y) = $path->n_to_xy($pos_infinity);
        if ($path->isa('Math::PlanePath::File')) {
          # all undefs for File
          if (! defined $x) { $x = $pos_infinity }
          if (! defined $y) { $y = $pos_infinity }
        } elsif ($path->isa('Math::PlanePath::PyramidRows')
                 && ! $parameters{'step'}) {
          # x==0 normal from step==0, fake it up to pass test
          if (defined $x && $x == 0) { $x = $pos_infinity }
        }
        (is_pos_infinity($x) || is_neg_infinity($x) || &$is_nan($x))
          or &$report("n_to_xy($pos_infinity) x is $x");
        (is_pos_infinity($y) || is_neg_infinity($y) || &$is_nan($y))
          or &$report("n_to_xy($pos_infinity) y is $y");
      }
      {
        ### n_to_dxdy($pos_infinity) ...
        my @dxdy = $path->n_to_xy($pos_infinity);
        if ($path->isa('Math::PlanePath::File')) {
          # all undefs for File
          @dxdy = ($pos_infinity, $pos_infinity);
        }
        my $num_values = scalar(@dxdy);
        $num_values == 2
          or &$report("n_to_dxdy(pos_infinity) got $num_values values, want 2");
        my ($dx,$dy) = @dxdy;
        (is_pos_infinity($dx) || is_neg_infinity($dx) || &$is_nan($dx))
          or &$report("n_to_dxdy($pos_infinity) dx is $dx");
        (is_pos_infinity($dy) || is_neg_infinity($dy) || &$is_nan($dy))
          or &$report("n_to_dxdy($pos_infinity) dy is $dy");
      }
      foreach my $method ('n_to_rsquared','n_to_radius') {
        ### n_to_r pos_infinity ...
        my @ret = $path->$method($pos_infinity);
        if ($path->isa('Math::PlanePath::File')) {
          # all undefs for File
          @ret = ($pos_infinity);
        }
        my $num_values = scalar(@ret);
        $num_values == 1
          or &$report("$method(pos_infinity) got $num_values values, want 1");
        my ($ret) = @ret;
        # allow NaN too, since sqrt(+inf) in various classes gives nan
        (is_pos_infinity($ret) || &$is_nan($ret))
          or &$report("$method($pos_infinity) ",$ret," expected +infinity");
      }
      {
        ### tree_n_children($pos_infinity) ...
        my @children = $path->tree_n_children($pos_infinity);
      }
      {
        ### tree_n_num_children($pos_infinity) ...
        my $num_children = $path->tree_n_num_children($pos_infinity);
      }
      {
        ### tree_n_to_subheight($pos_infinity) ...
        my $height = $path->tree_n_to_subheight($pos_infinity);
        if ($path->tree_n_num_children($n_start)) {
          unless (! defined $height || is_pos_infinity($height)) {
            &$report("tree_n_to_subheight($pos_infinity) ",$height," expected +inf");
          }
        } else {
          unless (equal(0,$height)) {
            &$report("tree_n_to_subheight($pos_infinity) ",$height," expected 0");
          }
        }
      }
      # {
      #   ### _EXPERIMENTAL__tree_n_to_leafdist($pos_infinity) ...
      #   my $leafdist = $path->_EXPERIMENTAL__tree_n_to_leafdist($pos_infinity);
      # #   if ($path->tree_n_num_children($n_start)) {
      # #     unless (! defined $leafdist || is_pos_infinity($leafdist)) {
      # #       &$report("_EXPERIMENTAL__tree_n_to_leafdist($pos_infinity) ",$leafdist," expected +inf");
      # #     }
      # #   } else {
      # #     unless (equal(0,$leafdist)) {
      # #       &$report("_EXPERIMENTAL__tree_n_to_leafdist($pos_infinity) ",$leafdist," expected 0");
      # #     }
      # #   }
      # }
    }
    
    if (defined $neg_infinity) {
      {
        ### n_to_xy($neg_infinity) ...
        my @xy = $path->n_to_xy($neg_infinity);
        if ($path->isa('Math::PlanePath::Rows')) {
          # secret negative n for Rows
          my ($x, $y) = @xy;
          ($x==$pos_infinity || $x==$neg_infinity || &$is_nan($x))
            or &$report("n_to_xy($neg_infinity) x is $x");
          ($y==$neg_infinity)
            or &$report("n_to_xy($neg_infinity) y is $y");
        } elsif ($path->isa('Math::PlanePath::Columns')) {
          # secret negative n for Columns
          my ($x, $y) = @xy;
          ($x==$neg_infinity)
            or &$report("n_to_xy($neg_infinity) x is $x");
          ($y==$pos_infinity || $y==$neg_infinity || &$is_nan($y))
            or &$report("n_to_xy($neg_infinity) y is $y");
        } else {
          scalar(@xy) == 0
            or &$report("n_to_xy($neg_infinity) xy is ",join(',',@xy));
        }
      }
      {
        ### n_to_dxdy($neg_infinity) ...
        my @dxdy = $path->n_to_xy($neg_infinity);
        my $num_values = scalar(@dxdy);
        if (($path->isa('Math::PlanePath::Rows')
             || $path->isa('Math::PlanePath::Columns'))
            && $num_values == 2) {
          # Rows,Columns has secret values for negative N, pretend not
          $num_values = 0;
        }
        $num_values == 0
          or &$report("n_to_dxdy(neg_infinity) got $num_values values, want 0");
      }
      
      foreach my $method ('n_to_rsquared','n_to_radius') {
        ### n_to_r (neg_infinity) ...
        my @ret = $path->$method($neg_infinity);
        if ($path->isa('Math::PlanePath::File')) {
          @ret = (undef);  # all undefs for File
        }
        my $num_values = scalar(@ret);
        $num_values == 1
          or &$report("$method($neg_infinity) got $num_values values, want 1");
        if ($path->isa('Math::PlanePath::Rows')
            || $path->isa('Math::PlanePath::Columns')) {
          ### Rows,Columns has secret values for negative N, pretend not ...
          @ret = (undef);
        }
        my ($ret) = @ret;
        if (defined $ret) {
          &$report("$method($neg_infinity) $ret expected undef");
        }
      }
      {
        ### tree_n_children($neg_infinity) ...
        my @children = $path->tree_n_children($neg_infinity);
        if (@children) {
          &$report("tree_n_children($neg_infinity) ",@children," expected none");
        }
      }
      {
        ### tree_n_num_children($neg_infinity) ...
        my $num_children = $path->tree_n_num_children($neg_infinity);
        if (defined $num_children) {
          &$report("tree_n_children($neg_infinity) ",$num_children," expected undef");
        }
      }
      {
        ### tree_n_to_subheight($neg_infinity) ...
        my $height = $path->tree_n_to_subheight($neg_infinity);
        if ($path->tree_n_num_children($n_start)) {
          if (defined $height) {
            &$report("tree_n_to_subheight($neg_infinity) ",$height," expected undef");
          }
        }
      }
      if ($path->can('_EXPERIMENTAL__tree_n_to_leafdist')) {
        my $leafdist = $path->_EXPERIMENTAL__tree_n_to_leafdist($neg_infinity);
        if ($path->tree_n_num_children($n_start)) {
          if (defined $leafdist) {
            &$report("_EXPERIMENTAL__tree_n_to_leafdist($neg_infinity) ",$leafdist," expected undef");
          }
        }
      }
    }
    
    # nan input documented loosely as yet ...
    if (defined $nan) {
      {
        my @xy = $path->n_to_xy($nan);
        if ($path->isa('Math::PlanePath::File')) {
          # allow empty from File without filename
          if (! @xy) { @xy = ($nan, $nan); }
        } elsif ($path->isa('Math::PlanePath::PyramidRows')
                 && ! $parameters{'step'}) {
          # x==0 normal from step==0, fake it up to pass test
          if (defined $xy[0] && $xy[0] == 0) { $xy[0] = $nan }
        }
        my ($x, $y) = @xy;
        &$is_nan($x) or &$report("n_to_xy($nan) x not nan, got ", $x);
        &$is_nan($y) or &$report("n_to_xy($nan) y not nan, got ", $y);
      }
      {
        my @dxdy = $path->n_to_xy($nan);
        if ($path->isa('Math::PlanePath::File')
            && @dxdy == 0) {
          # allow empty from File without filename
          @dxdy = ($nan, $nan);
        }
        my $num_values = scalar(@dxdy);
        $num_values == 2
          or &$report("n_to_dxdy(nan) got $num_values values, want 2");
        my ($dx,$dy) = @dxdy;
        &$is_nan($dx) or &$report("n_to_dxdy($nan) dx not nan, got ", $dx);
        &$is_nan($dy) or &$report("n_to_dxdy($nan) dy not nan, got ", $dy);
      }
      {
        ### tree_n_children($nan) ...
        my @children = $path->tree_n_children($nan);
        # ENHANCE-ME: what should nan return?
        # if (@children) {
        #   &$report("tree_n_children($nan) ",@children," expected none");
        # }
      }
      {
        ### tree_n_num_children($nan) ...
        my $num_children = $path->tree_n_num_children($nan);
        # ENHANCE-ME: what should nan return?
        # &$is_nan($num_children)
        #   or &$report("tree_n_children($nan) ",$num_children," expected nan");
      }
      {
        ### tree_n_to_subheight($nan) ...
        my $height = $path->tree_n_to_subheight($nan);
        if ($path->tree_n_num_children($n_start)) {
          (! defined $height || &$is_nan($height))
            or &$report("tree_n_to_subheight($nan) ",$height," expected nan");
        }
      }
      # {
      #   ### _EXPERIMENTAL__tree_n_to_leafdist($nan) ...
      #   my $leafdist = $path->_EXPERIMENTAL__tree_n_to_leafdist($nan);
      #   if ($path->tree_n_num_children($n_start)) {
      #     (! defined $leafdist || &$is_nan($leafdist))
      #       or &$report("_EXPERIMENTAL__tree_n_to_leafdist($nan) ",$leafdist," expected nan");
      #   }
      # }
    }
    
    foreach my $x
      (0,
       pos_infinity_maybe(),
       neg_infinity_maybe(),
       dbl_max_for_class_xy($path),
       dbl_max_neg_for_class_xy($path)) {
      foreach my $y (0,
                     pos_infinity_maybe(),
                     neg_infinity_maybe(),,
                     dbl_max_for_class_xy($path),
                     dbl_max_neg_for_class_xy($path)) {
        next if ! defined $y;
        ### xy_to_n: $x, $y
        my @n = $path->xy_to_n($x,$y);
        scalar(@n) == 1
          or &$report("xy_to_n($x,$y) want 1 value, got ",scalar(@n));
        # my $n = $n[0];
        # &$is_infinity($n) or &$report("xy_to_n($x,$y) n not inf, got ",$n);
      }
    }
    
    foreach my $x1 (0,
                    pos_infinity_maybe(),
                    neg_infinity_maybe(),
                    dbl_max_for_class_rect($path),
                    dbl_max_neg_for_class_rect($path)) {
      foreach my $x2 (0,
                      pos_infinity_maybe(),
                      neg_infinity_maybe(),
                      dbl_max_for_class_rect($path),
                      dbl_max_neg_for_class_rect($path)) {
        foreach my $y1 (0,
                        pos_infinity_maybe(),
                        neg_infinity_maybe(),
                        dbl_max_for_class_rect($path),
                        dbl_max_neg_for_class_rect($path)) {
          foreach my $y2 (0,
                          pos_infinity_maybe(),
                          neg_infinity_maybe(),
                          dbl_max_for_class_rect($path),
                          dbl_max_neg_for_class_rect($path)) {
            
            my @nn = $path->rect_to_n_range($x1,$y1, $x2,$y2);
            scalar(@nn) == 2
              or &$report("rect_to_n_range($x1,$y1, $x2,$y2) want 2 values, got ",scalar(@nn));
            # &$is_infinity($n) or &$report("xy_to_n($x,$y) n not inf, got ",$n);
          }
        }
      }
    }
    
    my $x_minimum = $path->x_minimum;
    my $x_maximum = $path->x_maximum;
    my $y_minimum = $path->y_minimum;
    my $y_maximum = $path->y_maximum;
    
    my $sumxy_minimum = $path->sumxy_minimum;
    my $sumxy_maximum = $path->sumxy_maximum;
    my $sumabsxy_minimum = $path->sumabsxy_minimum;
    my $sumabsxy_maximum = $path->sumabsxy_maximum;
    my $diffxy_minimum = $path->diffxy_minimum;
    my $diffxy_maximum = $path->diffxy_maximum;
    my $absdiffxy_minimum = $path->absdiffxy_minimum;
    my $absdiffxy_maximum = $path->absdiffxy_maximum;
    my $gcdxy_minimum = $path->gcdxy_minimum;
    my $gcdxy_maximum = $path->gcdxy_maximum;
    my $turn_any_left     = $path->turn_any_left;
    my $turn_any_right    = $path->turn_any_right;
    my $turn_any_straight = $path->turn_any_straight;
    
    my %saw_n_to_xy;
    my %count_n_to_xy;
    my $got_x_negative_at_n;
    my $got_y_negative_at_n;
    my $got_x_minimum;
    my $got_y_minimum;
    my (@prev_x,@prev_y, @prev_dx,@prev_dy);
    my ($dx_minimum, $dy_minimum);
    my ($dx_maximum, $dy_maximum);
    my %seen_dxdy;
    my $seen__UNDOCUMENTED__dxdy_list_at_n;
    my $got_turn_any_left_at_n;
    my $got_turn_any_right_at_n;
    my $got_turn_any_straight_at_n;
    my @n_to_x;
    my @n_to_y;
    foreach my $n ($n_start .. $n_limit) {
      my ($x, $y) = $path->n_to_xy ($n)
        or next;
      $n_to_x[$n] = $x;
      $n_to_y[$n] = $y;
      defined $x or &$report("n_to_xy($n) X undef");
      defined $y or &$report("n_to_xy($n) Y undef");
      my $arm = $n % $arms_count;
      
      if ($x < 0) {
        if (! defined $got_x_negative_at_n) {
          $got_x_negative_at_n= $n;
        }
      }
      if ($y < 0) {
        if (! defined $got_y_negative_at_n) {
          $got_y_negative_at_n= $n;
        }
      }
      
      if (defined $x_minimum && $x < $x_minimum) {
        &$report("n_to_xy($n) X=$x below x_minimum=$x_minimum");
      }
      if (defined $x_maximum && $x > $x_maximum) {
        &$report("n_to_xy($n) X=$x below x_maximum=$x_maximum");
      }
      if (defined $y_minimum && $y < $y_minimum) {
        &$report("n_to_xy($n) Y=$y below y_minimum=$y_minimum");
      }
      if (defined $y_maximum && $y > $y_maximum) {
        &$report("n_to_xy($n) Y=$y below y_maximum=$y_maximum");
      }
      # if (! defined $got_x_minimum || $x < $got_x_minimum) {
      #   $got_x_minimum = $x;
      # }
      # if (! defined $got_y_minimum || $y < $got_y_minimum) {
      #   $got_y_minimum = $y;
      # }
      # if (! defined $got_x_maximum || $x < $got_x_maximum) {
      #   $got_x_maximum = $x;
      # }
      # if (! defined $got_y_maximum || $y < $got_y_maximum) {
      #   $got_y_maximum = $y;
      # }
      
      {
        my $sumxy = $x + $y;
        if (defined $sumxy_minimum && $sumxy < $sumxy_minimum) {
          &$report("n_to_xy($n) X+Y=$sumxy below sumxy_minimum=$sumxy_minimum");
        }
        if (defined $sumxy_maximum && $sumxy > $sumxy_maximum) {
          &$report("n_to_xy($n) X+Y=$sumxy above sumxy_maximum=$sumxy_maximum");
        }
      }
      {
        my $sumabsxy = abs($x) + abs($y);
        if (defined $sumabsxy_minimum && $sumabsxy < $sumabsxy_minimum) {
          &$report("n_to_xy($n) abs(X)+abs(Y)=$sumabsxy below sumabsxy_minimum=$sumabsxy_minimum");
        }
        if (defined $sumabsxy_maximum && $sumabsxy > $sumabsxy_maximum) {
          &$report("n_to_xy($n) abs(X)+abs(Y)=$sumabsxy above sumabsxy_maximum=$sumabsxy_maximum");
        }
      }
      
      {
        my $diffxy = $x - $y;
        if (defined $diffxy_minimum && $diffxy < $diffxy_minimum) {
          &$report("n_to_xy($n) X-Y=$diffxy below diffxy_minimum=$diffxy_minimum");
        }
        if (defined $diffxy_maximum && $diffxy > $diffxy_maximum) {
          &$report("n_to_xy($n) X-Y=$diffxy above diffxy_maximum=$diffxy_maximum");
        }
      }
      {
        my $absdiffxy = abs($x - $y);
        if (defined $absdiffxy_minimum && $absdiffxy < $absdiffxy_minimum) {
          &$report("n_to_xy($n) abs(X-Y)=$absdiffxy below absdiffxy_minimum=$absdiffxy_minimum");
        }
        if (defined $absdiffxy_maximum && $absdiffxy > $absdiffxy_maximum) {
          &$report("n_to_xy($n) abs(X-Y)=$absdiffxy above absdiffxy_maximum=$absdiffxy_maximum");
        }
      }
      
      {
        my $gcdxy = gcd(abs($x),abs($y));
        if (defined $gcdxy_minimum && $gcdxy < $gcdxy_minimum) {
          &$report("n_to_xy($n) gcd($x,$y)=$gcdxy below gcdxy_minimum=$gcdxy_minimum");
        }
        if (defined $gcdxy_maximum && $gcdxy > $gcdxy_maximum) {
          &$report("n_to_xy($n) gcd($x,$y)=$gcdxy above gcdxy_maximum=$gcdxy_maximum");
        }
      }

      my $xystr = (int($x) == $x && int($y) == $y
                   ? sprintf('%d,%d', $x,$y)
                   : sprintf('%.3f,%.3f', $x,$y));
      if ($count_n_to_xy{$xystr}++ > $xy_maximum_duplication) {
        unless ($x == 0 && $y == 0
                && $count_n_to_xy{$xystr} <= $xy_maximum_duplication_at_origin{$class}) {
          &$report ("n_to_xy($n) duplicate$count_n_to_xy{$xystr} xy=$xystr prev n=$saw_n_to_xy{$xystr}");
        }
      }
      $saw_n_to_xy{$xystr} = $n;
      
      my ($dx,$dy);
      if (defined $prev_x[$arm]) { $dx = $x - $prev_x[$arm]; }
      if (defined $prev_y[$arm]) { $dy = $y - $prev_y[$arm]; }
      $prev_x[$arm] = $x;
      $prev_y[$arm] = $y;
      
      my $dxdy_str = (defined $dx && defined $dy ? "$dx,$dy" : undef);
      if (defined $dxdy_str) {
        if (! defined $seen_dxdy{$dxdy_str}) {
          $seen_dxdy{$dxdy_str} ||= [$dx,$dy];
          $seen__UNDOCUMENTED__dxdy_list_at_n = $n-$arms_count;
        }
        if (@_UNDOCUMENTED__dxdy_list) {
          $_UNDOCUMENTED__dxdy_list{$dxdy_str}
            or &$report ("N=$n dxdy=$dxdy_str not in _UNDOCUMENTED__dxdy_list");
        }
      }
      if (defined $dx) {
        if (! defined $dx_maximum || $dx > $dx_maximum) { $dx_maximum = $dx; }
        if (! defined $dx_minimum || $dx < $dx_minimum) { $dx_minimum = $dx; }
      }
      if (defined $dy) {
        if (! defined $dy_maximum || $dy > $dy_maximum) { $dy_maximum = $dy; }
        if (! defined $dy_minimum || $dy < $dy_minimum) { $dy_minimum = $dy; }
      }

      # FIXME: Rows and Columns shouldn't take turn from negative N?
      my $LSR = ($n < $n_start + $arms_count ? undef
                 : $path->_UNDOCUMENTED__n_to_turn_LSR($n));
      my $prev_dx = $prev_dx[$arm];
      my $prev_dy = $prev_dy[$arm];
      if (defined $LSR) {

        # print "turn N=$n_of_turn at $x,$y  dxdy prev $prev_dx,$prev_dy this $dx,$dy  is LSR=$LSR\n";
        if ($LSR > 0)  {
          $turn_any_left 
            or &$report ("turn_any_left() false but left at N=$n");
          if (! defined $got_turn_any_left_at_n) { $got_turn_any_left_at_n = $n; }
        }
        if (! $LSR) {
          $turn_any_straight 
            or &$report ("turn_any_straight() false but straight at N=$n");
          if (! defined $got_turn_any_straight_at_n) { $got_turn_any_straight_at_n = $n; }
          # print "straight at N=$n_of_turn   dxdy $prev_dx,$prev_dy then $dx,$dy\n";
        }
        if ($LSR < 0)  {
          $turn_any_right 
            or &$report ("turn_any_right() false but right at N=$n");
          if (! defined $got_turn_any_right_at_n) { $got_turn_any_right_at_n = $n; }
        }
      }
      $prev_dx[$arm] = $dx;
      $prev_dy[$arm] = $dy;
      
      {
        my $x2 = $x + ($x >= 0 ? .4 : -.4);
        my $y2 = $y + ($y >= 0 ? .4 : -.4);
        my ($n_lo, $n_hi) = $path->rect_to_n_range
          (0,0, $x2,$y2);
        $n_lo <= $n
          or &$report ("rect_to_n_range(0,0, $x2,$y2) lo n=$n xy=$xystr, got n_lo=$n_lo");
        $n_hi >= $n
          or &$report ("rect_to_n_range(0,0, $x2,$y2) hi n=$n xy=$xystr, got n_hi=$n_hi");
        $n_lo == int($n_lo)
          or &$report ("rect_to_n_range(0,0, $x2,$y2) lo n=$n xy=$xystr, got n_lo=$n_lo, integer");
        $n_hi == int($n_hi)
          or &$report ("rect_to_n_range(0,0, $x2,$y2) hi n=$n xy=$xystr, got n_hi=$n_hi, integer");
        $n_lo >= $n_start
          or &$report ("rect_to_n_range(0,0, $x2,$y2) n_lo=$n_lo is before n_start=$n_start");
      }
      {
        my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
        ($rect_exact{$class} ? $n_lo == $n : $n_lo <= $n)
          or &$report ("rect_to_n_range() lo n=$n xy=$xystr, got $n_lo");
        ($rect_exact_hi{$class} ? $n_hi == $n : $n_hi >= $n)
          or &$report ("rect_to_n_range() hi n=$n xy=$xystr, got $n_hi");
        $n_lo == int($n_lo)
          or &$report ("rect_to_n_range() lo n=$n xy=$xystr, got n_lo=$n_lo, should be an integer");
        $n_hi == int($n_hi)
          or &$report ("rect_to_n_range() hi n=$n xy=$xystr, got n_hi=$n_hi, should be an integer");
        $n_lo >= $n_start
          or &$report ("rect_to_n_range() n_lo=$n_lo is before n_start=$n_start");
      }
      
      unless ($xy_maximum_duplication > 0) {
        foreach my $x_offset (0) { # bit slow: , -0.2, 0.2) {
          foreach my $y_offset (0, +0.2) { # bit slow: , -0.2) {
            my $rev_n = $path->xy_to_n ($x + $x_offset, $y + $y_offset);
            ### try xy_to_n from: "n=$n  xy=$x,$y xy=$xystr  x_offset=$x_offset y_offset=$y_offset"
            ### $rev_n
            unless (defined $rev_n && $n == $rev_n) {
              &$report ("xy_to_n() rev n=$n xy=$xystr x_offset=$x_offset y_offset=$y_offset got ".(defined $rev_n ? $rev_n : 'undef'));
              pythagorean_diag($path,$x,$y);
            }
          }
        }
      }
    }
    
    #--------------------------------------------------------------------------
    # turn_any_left(), turn_any_straight(), turn_any_right()

    if ($turn_any_left && ! defined $got_turn_any_left_at_n) {
      my $at_n;
      if ($path->can('_UNDOCUMENTED__turn_any_left_at_n')) {
        $at_n = $path->_UNDOCUMENTED__turn_any_left_at_n;
      }
      if (defined $at_n && $n_limit <= $at_n) {
        MyTestHelpers::diag ("  skip n_limit=$n_limit < turn left at_n=$at_n");
      } elsif ($path->isa('Math::PlanePath::File')) {
        MyTestHelpers::diag ("  skip turn_any_left() not established for File");
      } else {
        &$report ("turn_any_left() true but not seen to N=$n_limit");
      }
    }
    if ($turn_any_straight && ! defined $got_turn_any_straight_at_n) {
      my $at_n;
      if ($path->can('_UNDOCUMENTED__turn_any_straight_at_n')) {
        $at_n = $path->_UNDOCUMENTED__turn_any_straight_at_n;
      }
      if (defined $at_n && $n_limit <= $at_n) {
        MyTestHelpers::diag ("  skip n_limit=$n_limit < turn straight at_n=$at_n");
      } elsif ($path->isa('Math::PlanePath::File')) {
        MyTestHelpers::diag ("  skip turn_any_straight() not established for File");
      } elsif ($path->isa('Math::PlanePath::MultipleRings')
               && $path->{'ring_shape'} eq 'polygon'
               && $path->{'step'} == 8) {
        MyTestHelpers::diag ("  skip MultipleRings,ring_shape=polygon,step=8 turn_any_straight() due to round-off");
      } else {
        &$report ("turn_any_straight() true but not seen to N=$n_limit");
      }
    }
    if ($turn_any_right && ! defined $got_turn_any_right_at_n) {
      my $at_n;
      if ($path->can('_UNDOCUMENTED__turn_any_right_at_n')) {
        $at_n = $path->_UNDOCUMENTED__turn_any_right_at_n;
      }
      if (defined $at_n && $n_limit <= $at_n) {
        MyTestHelpers::diag ("  skip n_limit=$n_limit < turn right at_n=$at_n");
      } elsif ($path->isa('Math::PlanePath::File')) {
        MyTestHelpers::diag ("  skip turn_any_right() not established for File");
      } else {
        &$report ("turn_any_right() true but not seen to N=$n_limit");
      }
    }

    foreach my $elem
      (['_UNDOCUMENTED__turn_any_left_at_n',    1,$got_turn_any_left_at_n ],
       ['_UNDOCUMENTED__turn_any_straight_at_n',0,$got_turn_any_straight_at_n ],
       ['_UNDOCUMENTED__turn_any_right_at_n',  -1,$got_turn_any_right_at_n ]){
      my ($method, $want_LSR, $seen_at_n) = @$elem;
      if ($path->can($method)) {
        if (defined(my $n = $path->$method)) {
          my $got_LSR = $path->_UNDOCUMENTED__n_to_turn_LSR($n);
          $got_LSR == $want_LSR
            or &$report ("$method()=$n got LSR=$got_LSR want $want_LSR");
          if (defined $seen_at_n) {
            $n == $seen_at_n
              or &$report ("$method()=$n but saw first at N=$seen_at_n");
          }
        }
      }
    }

    #--------------------------------------------------------------------------
    ### n_to_xy() fractional ...
    
    unless ($non_linear_frac{$class}
            || defined $n_frac_discontinuity) {
      foreach my $n ($n_start .. $#n_to_x - $arms_count) {
        my $x = $n_to_x[$n];
        my $y = $n_to_y[$n];
        my $next_x = $n_to_x[$n+$arms_count];
        my $next_y = $n_to_y[$n+$arms_count];
        next unless defined $x && defined $next_x;
        my $dx = $next_x - $x;
        my $dy = $next_y - $y;
        foreach my $frac (0.25, 0.75) {
          my $n_frac = $n + $frac;
          my ($got_x,$got_y) = $path->n_to_xy($n_frac);
          my $want_x = $x + $frac*$dx;
          my $want_y = $y + $frac*$dy;
          abs($want_x - $got_x) < 0.00001
            or &$report ("n_to_xy($n_frac) got_x=$got_x want_x=$want_x");
          abs($want_y - $got_y) < 0.00001
            or &$report ("n_to_xy($n_frac) got_y=$got_y want_y=$want_y");
        }
      }
    }
    
    #--------------------------------------------------------------------------
    ### n_to_dxdy() ...
    
    if ($path->can('n_to_dxdy') != Math::PlanePath->can('n_to_dxdy')) {
      MyTestHelpers::diag ($mod, ' n_to_dxdy()');
      foreach my $n ($n_start .. $#n_to_x - $arms_count) {
        my $x = $n_to_x[$n];
        my $y = $n_to_y[$n];
        my $next_x = $n_to_x[$n+$arms_count];
        my $next_y = $n_to_y[$n+$arms_count];
        next unless defined $x && defined $next_x;
        my $want_dx = $next_x - $x;
        my $want_dy = $next_y - $y;
        my ($got_dx,$got_dy) = $path->n_to_dxdy($n);
        $want_dx == $got_dx
          or &$report ("n_to_dxdy($n) got_dx=$got_dx want_dx=$want_dx  (next_x=$n_to_x[$n+$arms_count], x=$n_to_x[$n])");
        $want_dy == $got_dy
          or &$report ("n_to_dxdy($n) got_dy=$got_dy want_dy=$want_dy");
      }
      
      foreach my $n ($n_start .. $n_limit) {
        foreach my $offset (0.25, 0.75) {
          my $n = $n + $offset;
          my ($x,$y) = $path->n_to_xy($n);
          my ($next_x,$next_y) = $path->n_to_xy($n+$arms_count);
          my $want_dx = ($next_x - $x);
          my $want_dy = ($next_y - $y);
          my ($got_dx,$got_dy) = $path->n_to_dxdy($n);
          $want_dx == $got_dx
            or &$report ("n_to_dxdy($n) got_dx=$got_dx want_dx=$want_dx");
          $want_dy == $got_dy
            or &$report ("n_to_dxdy($n) got_dy=$got_dy want_dy=$want_dy");
        }
      }
    }
    
    #--------------------------------------------------------------------------
    ### n_to_rsquared() vs X^2,Y^2 ...
    
    if ($path->can('n_to_rsquared') != Math::PlanePath->can('n_to_rsquared')) {
      foreach my $n ($n_start .. $#n_to_x) {
        my $x = $n_to_x[$n];
        my $y = $n_to_y[$n];
        my ($n_to_rsquared) = $path->n_to_rsquared($n);
        my $xy_to_rsquared = $x*$x + $y*$y;
        if (abs($n_to_rsquared - $xy_to_rsquared) > 0.0000001) {
          &$report ("n_to_rsquared() at n=$n,x=$x,y=$y got $n_to_rsquared whereas x^2+y^2=$xy_to_rsquared");
        }
      }
    }
    
    #--------------------------------------------------------------------------
    ### n_to_radius() vs X^2,Y^2 ...
    
    if ($path->can('n_to_radius') != Math::PlanePath->can('n_to_radius')) {
      foreach my $n ($n_start .. $#n_to_x) {
        my $x = $n_to_x[$n];
        my $y = $n_to_y[$n];
        my ($n_to_radius) = $path->n_to_radius($n);
        my $xy_to_radius = sqrt($x*$x + $y*$y);
        if (abs($n_to_radius - $xy_to_radius) > 0.0000001) {
          &$report ("n_to_radius() at n=$n,x=$x,y=$y got $n_to_radius whereas x^2+y^2=$xy_to_radius");
        }
      }
    }
    
    #--------------------------------------------------------------------------
    ### _NOTDOCUMENTED_n_to_figure_boundary() ...
    
    if ($path->can('_NOTDOCUMENTED_n_to_figure_boundary')) {
      my $want = 4;
      my $bad = 0;
      foreach my $n ($n_start .. $n_start + 1000) {
        my $got = $path->_NOTDOCUMENTED_n_to_figure_boundary($n);
        if ($want != $got) {
          my ($x,$y) = $path->n_to_xy($n);
          &$report ("_NOTDOCUMENTED_n_to_figure_boundary() at n=$n,x=$x,y=$y got $got whereas want $want");
          last if $bad++ > 20;
        }
        $want += path_n_to_dboundary($path,$n);
      }
    }
    
    #--------------------------------------------------------------------------
    ### level_to_n_range() and with n_to_level() ...
    
    foreach my $n ($n_start-1, $n_start-100) {
      my $got = $path->n_to_level($n);
      if (defined $got) {
        &$report ("n_to_level() not undef on N=$n before n_start=$n_start");
      }
    }
    my $have_level_to_n_range = do {
      my @n_range = $path->level_to_n_range(0);
      scalar(@n_range)
    };
    if ($have_level_to_n_range) {
      my @n_range;
      my $bad = 0;
      foreach my $n ($n_start .. $n_start+100) {
        my $level = $path->n_to_level($n);
        if (! defined $level) {
          &$report ("n_to_level($n) undef");
          last;
        }
        if ($level < 0) {
          &$report ("n_to_level() negative");
          last if $bad++ > 10;
          next;
        }
        $n_range[$level] ||= [ $path->level_to_n_range($level) ];
        my ($n_lo, $n_hi) = @{$n_range[$level]};
        unless ($n >= $n_lo && $n <= $n_hi) {
          &$report ("n_to_level($n)=$level has $n outside $n_lo .. $n_hi");
          last if $bad++ > 10;
        }
      }
    }

    # n_to_level() just before and after level_to_n_range() high limit
    if ($have_level_to_n_range) {
      foreach my $level (0 .. 10) {
        my ($n_lo, $n_hi) = $path->level_to_n_range($level);
        last if $n_hi > 2**24;
        foreach my $offset (-6 .. 0) {
          my $n = $n_hi + $offset;
          next if $n < $n_start;
          my $got_level = $path->n_to_level($n_hi);
          unless ($got_level == $level) {
            &$report ("n_to_level(n_hi$offset=$n)=$got_level but level_to_n_range($level)= $n_lo .. $n_hi");
          }
        }
        foreach my $offset (1 .. 6) {
          my $n = $n_hi + $offset;
          my $got_level = $path->n_to_level($n_hi+1);
          my $want_level = $level+1;
          unless ($got_level == $want_level) {
            &$report ("n_to_level(n_hi+$offset=$n)=$got_level but level_to_n_range($level)= $n_lo .. $n_hi want $want_level");
          }
        }
      }
    }
    
    #--------------------------------------------------------------------------
    ### n_to_xy() various bogus values return 0 or 2 values and not crash ...
    
    foreach my $n (-100, -2, -1, -0.6, -0.5, -0.4,
                   0, 0.4, 0.5, 0.6) {
      my @xy = $path->n_to_xy ($n);
      (@xy == 0 || @xy == 2)
        or &$report ("n_to_xy() n=$n got ",scalar(@xy)," values");
    }
    
    foreach my $elem ([-1,-1, -1,-1],
                     ) {
      my ($x1,$y1,$x2,$y2) = @$elem;
      my ($got_lo, $got_hi) = $path->rect_to_n_range ($x1,$y1, $x2,$y2);
      (defined $got_lo && defined $got_hi)
        or &$report ("rect_to_n_range() x1=$x1,y1=$y1, x2=$x2,y2=$y2 undefs");
      if ($got_hi >= $got_lo) {
        $got_lo >= $n_start
          or &$report ("rect_to_n_range() got_lo=$got_lo is before n_start=$n_start");
      }
    }
    
    #--------------------------------------------------------------------------
    ### _UNDOCUMENTED__n_is_x_positive() ...
    
    if ($path->can('_UNDOCUMENTED__n_is_x_positive')) {
      foreach my $n (0 .. $arms_count * 256) {
        my ($x,$y) = $path->n_to_xy($n);
        my $want = ($x >= 0 && $y == 0 ? 1 : 0);
        my $got = $path->_UNDOCUMENTED__n_is_x_positive($n) ? 1 : 0;
        unless ($got == $want) {
          &$report ("_UNDOCUMENTED__n_is_x_positive() n=$n want $want got $got");
        }
      }
    }
    
    #--------------------------------------------------------------------------
    ### _UNDOCUMENTED__n_is_diagonal_NE() ...
    
    if ($path->can('_UNDOCUMENTED__n_is_diagonal_NE')) {
      foreach my $n (0 .. $arms_count * 256) {
        my ($x,$y) = $path->n_to_xy($n);
        my $want = ($x >= 0 && $x == $y ? 1 : 0);
        my $got = $path->_UNDOCUMENTED__n_is_diagonal_NE($n) ? 1 : 0;
        unless ($got == $want) {
          &$report ("_UNDOCUMENTED__n_is_diagonal_NE() n=$n want $want got $got");
        }
      }
    }
    
    #--------------------------------------------------------------------------
    ### _UNDOCUMENTED__dxdy_list() completeness ...
    
    if (@_UNDOCUMENTED__dxdy_list) {
      my $_UNDOCUMENTED__dxdy_list_at_n;
      my $dxdy_num = int(scalar(@_UNDOCUMENTED__dxdy_list)/2);
      my $seen_dxdy_num = scalar keys %seen_dxdy;
      $_UNDOCUMENTED__dxdy_list_at_n = $path->_UNDOCUMENTED__dxdy_list_at_n;
      if (defined $_UNDOCUMENTED__dxdy_list_at_n) {
        $_UNDOCUMENTED__dxdy_list_at_n >= $n_start
          or &$report ("_UNDOCUMENTED__dxdy_list_at_n() = $_UNDOCUMENTED__dxdy_list_at_n is < n_start=$n_start");
        if ($seen_dxdy_num == $dxdy_num) {
          $seen__UNDOCUMENTED__dxdy_list_at_n == $_UNDOCUMENTED__dxdy_list_at_n
            or &$report ("_UNDOCUMENTED__dxdy_list_at_n() = $_UNDOCUMENTED__dxdy_list_at_n but seen__UNDOCUMENTED__dxdy_list_at_n=$seen__UNDOCUMENTED__dxdy_list_at_n");
        }
      } else {
        $_UNDOCUMENTED__dxdy_list_at_n = $n_start;
      }
      if ($n_limit - $arms_count < $_UNDOCUMENTED__dxdy_list_at_n) {
        MyTestHelpers::diag ("  skip n_limit=$n_limit <= _UNDOCUMENTED__dxdy_list_at_n=$_UNDOCUMENTED__dxdy_list_at_n");
      } else {
        foreach my $dxdy_str (keys %_UNDOCUMENTED__dxdy_list) {
          if (! $seen_dxdy{$dxdy_str}) {
            &$report ("_UNDOCUMENTED__dxdy_list() has $dxdy_str not seen to n_limit=$n_limit");
          }
        }
      }
      
    } else {
      my $seen_dxdy_count = scalar keys %seen_dxdy;
      if ($seen_dxdy_count > 0
          && $seen_dxdy_count <= 10
          && ($dx_maximum||0) < 4
          && ($dy_maximum||0) < 4
          && ($dx_minimum||0) > -4
          && ($dy_minimum||0) > -4) {
        MyTestHelpers::diag ("  possible dxdy list: ", join(' ', keys %seen_dxdy));
      }
    }

    #--------------------------------------------------------------------------
    ### x negative xy_to_n() ...

    foreach my $x (-100, -99) {
      ### $x
      my @n = $path->xy_to_n ($x,-1);
      ### @n
      (scalar(@n) == 1)
        or &$report ("xy_to_n($x,-1) array context got ",scalar(@n)," values but should be 1, possibly undef");
    }

    {
      my $x_negative = ($path->x_negative ? 1 : 0);
      my $got_x_negative = (defined $got_x_negative_at_n ? 1 : 0);

      # if ($mod eq 'ComplexPlus,realpart=2'
      #     || $mod eq 'ComplexPlus,realpart=3'
      #     || $mod eq 'ComplexPlus,realpart=4'
      #     || $mod eq 'ComplexPlus,realpart=5'
      #    ) {
      #   # these don't get to X negative in small rectangle
      #   $got_x_negative = 1;
      # }

      if ($n_limit < (defined $x_negative_at_n ? $x_negative_at_n : $n_start)) {
        MyTestHelpers::diag ("  skip n_limit=$n_limit <= x_negative_at_n=$x_negative_at_n");
      } else {
        ($x_negative == $got_x_negative)
          or &$report ("x_negative() $x_negative but in rect to n=$limit got $got_x_negative (x_negative_at_n=$x_negative_at_n)");
      }
      if (defined $got_x_negative_at_n) {
        equal($x_negative_at_n, $got_x_negative_at_n)
          or &$report ("x_negative_at_n() = ",$x_negative_at_n," but got_x_negative_at_n=$got_x_negative_at_n");
      }

      if (defined $x_negative_at_n && $x_negative_at_n < 0x100_0000) {
        {
          my ($x,$y) = $path->n_to_xy($x_negative_at_n);
          $x < 0 or &$report ("x_negative_at_n()=$x_negative_at_n but xy=$x,$y");
        }
        if ($x_negative_at_n > $n_start) {
          my $n = $x_negative_at_n - 1;
          my ($x,$y) = $path->n_to_xy($n);
          $x >= 0 or &$report ("x_negative_at_n()=$x_negative_at_n but at N=$n xy=$x,$y");
        }
      }
    }
    {
      my $y_negative = ($path->y_negative ? 1 : 0);
      my $got_y_negative = (defined $got_y_negative_at_n ? 1 : 0);

      # if (($mod eq 'ComplexPlus' && $limit < 32) # first y_neg at N=32
      #     || $mod eq 'ComplexPlus,realpart=2'  # y_neg big
      #     || $mod eq 'ComplexPlus,realpart=3'
      #     || $mod eq 'ComplexPlus,realpart=4'
      #     || $mod eq 'ComplexPlus,realpart=5'
      #     || $mod eq 'ComplexMinus,realpart=3'
      #     || $mod eq 'ComplexMinus,realpart=4'
      #     || $mod eq 'ComplexMinus,realpart=5'
      #    ) {
      #   # GosperSide take a long time to get
      #   # to Y negative, not reached by the rectangle
      #   # considered here.  ComplexMinus doesn't get there
      #   # on realpart==5 or bigger too.
      #   $got_y_negative = 1;
      # }

      if ($n_limit < (defined $y_negative_at_n ? $y_negative_at_n : $n_start)) {
        MyTestHelpers::diag ("  skip n_limit=$n_limit <= y_negative_at_n=$y_negative_at_n");
      } else {
        ($y_negative == $got_y_negative)
          or &$report ("y_negative() $y_negative but in rect to n=$limit got $got_y_negative (y_negative_at_n=$y_negative_at_n)");
      }
      if (defined $got_y_negative_at_n) {
        equal($y_negative_at_n, $got_y_negative_at_n)
          or &$report ("y_negative_at_n() = ",$y_negative_at_n," but got_y_negative_at_n=$got_y_negative_at_n");
      }

      if (defined $y_negative_at_n && $y_negative_at_n < 0x100_0000) {
        {
          # n_to_xy() of y_negative_at_n should be Y < 0
          my ($x,$y) = $path->n_to_xy($y_negative_at_n);
          $y < 0 or &$report ("y_negative_at_n()=$y_negative_at_n but xy=$x,$y");
        }
        {
          # n_to_xy() of y_negative_at_n - 1 should be Y >= 0,
          # unless y_negative_at_n is at n_start
          my $n = $y_negative_at_n - 1;
          if ($n >= $n_start) {
            my ($x,$y) = $path->n_to_xy($n);
            $y >= 0 or &$report ("y_negative_at_n()=$y_negative_at_n but at N=$n xy=$x,$y");
          }
        }
      }
    }

    if ($path->figure ne 'circle'
        # bit slow
        && ! ($path->isa('Math::PlanePath::Flowsnake'))) {

      my $x_min = ($path->x_negative ? - int($rect_limit/2) : -2);
      my $y_min = ($path->y_negative ? - int($rect_limit/2) : -2);
      my $x_max = $x_min + $rect_limit;
      my $y_max = $y_min + $rect_limit;
      my $data;
      foreach my $x ($x_min .. $x_max) {
        foreach my $y ($y_min .. $y_max) {
          my $n = $path->xy_to_n ($x, $y);
          if (defined $n && $n < $n_start
              && ! $path->isa('Math::PlanePath::Rows')
              && ! $path->isa('Math::PlanePath::Columns')) {
            &$report ("xy_to_n($x,$y) gives n=$n < n_start=$n_start");
          }
          $data->{$y}->{$x} = $n;
        }
      }
      #### $data

      # MyTestHelpers::diag ("rect check ...");
      foreach my $y1 ($y_min .. $y_max) {
        foreach my $y2 ($y1 .. $y_max) {

          foreach my $x1 ($x_min .. $x_max) {
            my $min;
            my $max;

            foreach my $x2 ($x1 .. $x_max) {
              my @col = map {$data->{$_}->{$x2}} $y1 .. $y2;
              @col = grep {defined} @col;
              $min = List::Util::min (grep {defined} $min, @col);
              $max = List::Util::max (grep {defined} $max, @col);
              my $want_min = (defined $min ? $min : 1);
              my $want_max = (defined $max ? $max : 0);
              ### @col
              ### rect: "$x1,$y1  $x2,$y2  expect N=$want_min..$want_max"

              foreach my $x_swap (0, 1) {
                my ($x1,$x2) = ($x_swap ? ($x1,$x2) : ($x2,$x1));
                foreach my $y_swap (0, 1) {
                  my ($y1,$y2) = ($y_swap ? ($y1,$y2) : ($y2,$y1));

                  my ($got_min, $got_max)
                    = $path->rect_to_n_range ($x1,$y1, $x2,$y2);
                  defined $got_min
                    or &$report ("rect_to_n_range($x1,$y1, $x2,$y2) got_min undef");
                  defined $got_max
                    or &$report ("rect_to_n_range($x1,$y1, $x2,$y2) got_max undef");
                  if ($got_max >= $got_min) {
                    $got_min >= $n_start
                      or $rect_before_n_start{$class}
                        or &$report ("rect_to_n_range() got_min=$got_min is before n_start=$n_start");
                  }

                  if (! defined $min || ! defined $max) {
                    if (! $rect_exact_hi{$class}) {
                      next; # outside
                    }
                  }

                  unless ($rect_exact{$class}
                          ? $got_min == $want_min
                          : $got_min <= $want_min) {
                    ### $x1
                    ### $y1
                    ### $x2
                    ### $y2
                    ### got: $path->rect_to_n_range ($x1,$y1, $x2,$y2)
                    ### $want_min
                    ### $want_max
                    ### $got_min
                    ### $got_max
                    ### @col
                    ### $data
                    &$report ("rect_to_n_range($x1,$y1, $x2,$y2) bad min  got_min=$got_min want_min=$want_min".(defined $min ? '' : '[nomin]')
                             );
                  }
                  unless ($rect_exact_hi{$class}
                          ? $got_max == $want_max
                          : $got_max >= $want_max) {
                    &$report ("rect_to_n_range($x1,$y1, $x2,$y2 ) bad max got $got_max want $want_max".(defined $max ? '' : '[nomax]'));
                  }
                }
              }
            }
          }
        }
      }

      if ($path->can('xy_is_visited') != Math::PlanePath->can('xy_is_visited')) {
        # MyTestHelpers::diag ("xy_is_visited() check ...");
        foreach my $y ($y_min .. $y_max) {
          foreach my $x ($x_min .. $x_max) {
            my $got_visited = ($path->xy_is_visited($x,$y) ? 1 : 0);
            my $want_visited = (defined($data->{$y}->{$x}) ? 1 : 0);
            unless ($got_visited == $want_visited) {
              &$report ("xy_is_visited($x,$y) got $got_visited want $want_visited");
            }
          }
        }
      }
    }

    my $is_a_tree;
    {
      my @n_children = $path->tree_n_children($n_start);
      if (@n_children) {
        $is_a_tree = 1;
      }
    }

    my $num_children_minimum = $path->tree_num_children_minimum;
    my $num_children_maximum = $path->tree_num_children_maximum;
    ($num_children_maximum >= $num_children_minimum)
      or &$report ("tree_num_children_maximum() is ",$num_children_maximum,
                   "expect >= tree_num_children_minimum() is ",$num_children_minimum);

    my @num_children_list = $path->tree_num_children_list;
    my $num_children_list_str = join(',',@num_children_list);
    my %num_children_hash;
    @num_children_hash{@num_children_list} = (); # hash slice
    @num_children_list >= 1
      or &$report ("tree_num_children_list() is empty");
    $num_children_list[0] == $num_children_minimum
      or &$report ("tree_num_children_list() first != minimum");
    $num_children_list[-1] == $num_children_maximum
      or &$report ("tree_num_children_list() last != maximum");
    join(',',sort {$a<=>$b} @num_children_list) eq $num_children_list_str
      or &$report ("tree_num_children_list() not sorted");

    # tree_any_leaf() is the same as tree_num_children_minimum()==0
    my $any_leaf = $path->tree_any_leaf;
    ((!!$any_leaf) == ($num_children_minimum==0))
      or &$report ("tree_any_leaf() is ",$any_leaf," but tree_num_children_minimum() is ",$num_children_minimum);

    my $num_roots = $path->tree_num_roots;
    if ($is_a_tree) {
      $num_roots > 0
        or &$report ("tree_num_roots() should be > 0, got ", $num_roots);
    } else {
      $num_roots == 0
        or &$report ("tree_num_roots() should be 0 for non-tree, got ", $num_roots);
    }

    my @root_n_list = $path->tree_root_n_list;
    my $root_n_list_str = join(',',@root_n_list);
    scalar(@root_n_list) == $num_roots
      or &$report ("tree_root_n_list() $root_n_list_str expected num_roots=$num_roots many values");
    my %root_n_list;
    foreach my $root_n (@root_n_list) {
      if (exists $root_n_list{$root_n}) {
        &$report ("tree_root_n_list() duplicate $root_n in list $root_n_list_str");
      }
      $root_n_list{$root_n} = 1;
    }

    ### tree_n_root() of each ...
    my $have_class_tree_n_root
      = ($path->can('tree_n_root') != Math::PlanePath->can('tree_n_root'));
    if ($have_class_tree_n_root) {
      MyTestHelpers::diag ("tree_n_root() specific implementation ...");
    }

    foreach my $n ($n_start .. $n_start+$limit) {
      my $root_n = $path->tree_n_root($n);
      if ($is_a_tree) {
        if (! defined $root_n || ! $root_n_list{$root_n}) {
          &$report ("tree_n_root($n) got ",$root_n," is not a root ($root_n_list_str)");
        }
        if ($have_class_tree_n_root) {
          my $root_n_by_search = $path->Math::PlanePath::tree_n_root($n);
          $root_n == $root_n_by_search
            or &$report ("tree_n_root($n) got ",$root_n," but by search is ",$root_n_by_search);
        }
      } else {
        if (defined $root_n) {
          &$report ("tree_n_root($n) got ",$root_n," expected undef for non-tree");
        }
      }
    }

    ### tree_n_children before n_start ...
    foreach my $n ($n_start-5 .. $n_start-1) {
      {
        my @n_children = $path->tree_n_children($n);
        (@n_children == 0)
          or &$report ("tree_n_children($n) before n_start=$n_start unexpectedly got ",scalar(@n_children)," values:",@n_children);
      }
      {
        my $num_children = $path->tree_n_num_children($n);
        if (defined $num_children) {
          &$report ("tree_n_num_children($n) before n_start=$n_start unexpectedly $num_children not undef");
        }
      }
    }

    ### tree_n_parent() before n_start ...
    foreach my $n ($n_start-5 .. $n_start) {
      my $n_parent = $path->tree_n_parent($n);
      if (defined $n_parent) {
        &$report ("tree_n_parent($n) <= n_start=$n_start unexpectedly got parent ",$n_parent);
      }
    }
    ### tree_n_children() look at tree_n_parent of each ...
    {
      my %unseen_num_children = %num_children_hash;
      foreach my $n ($n_start .. $n_start+$limit,
                     ($path->isa('Math::PlanePath::OneOfEight')
                      ? (37, # first with 2 children in parts=4
                         58) # first with 3 children in parts=4
                      : ())) {
        ### $n
        my @n_children = $path->tree_n_children($n);
        ### @n_children

        my $num_children = scalar(@n_children);
        exists $num_children_hash{$num_children}
          or &$report ("tree_n_children($n)=$num_children not in tree_num_children_list()=$num_children_list_str");

        delete $unseen_num_children{$num_children};

        foreach my $n_child (@n_children) {
          my $got_n_parent = $path->tree_n_parent($n_child);
          ($got_n_parent == $n)
            or &$report ("tree_n_parent($n_child) got $got_n_parent want $n");
        }
      }
      if (%unseen_num_children) {
        &$report ("tree_num_children_list() values not seen: ",
                  join(',',sort {$a<=>$b} keys %unseen_num_children),
                  " of total=$num_children_list_str");
      }
    }

    ### tree_n_to_depth() before n_start ...
    foreach my $n ($n_start-5 .. $n_start-1) {
      my $depth = $path->tree_n_to_depth($n);
      if (defined $depth) {
        &$report ("tree_n_to_depth($n) < n_start=$n_start unexpectedly got depth ",$depth);
      }
    }

    my @depth_to_width_by_count;
    my @depth_to_n_seen;
    my @depth_to_n_end_seen;

    if ($path->can('tree_n_to_depth')
        != Math::PlanePath->can('tree_n_to_depth')) {
      ### tree_n_to_depth() vs count up by parents ...
      # MyTestHelpers::diag ($mod, ' tree_n_to_depth()');
      foreach my $n ($n_start .. $n_start+$limit) {
        my $want_depth = path_tree_n_to_depth_by_parents($path,$n);
        my $got_depth = $path->tree_n_to_depth($n);

        if (! defined $got_depth || ! defined $want_depth
            || $got_depth != $want_depth) {
          &$report ("tree_n_to_depth($n) got ",$got_depth," want ",$want_depth);
        }
        if ($got_depth >= 0 && $got_depth <= $depth_limit) {
          $depth_to_width_by_count[$got_depth]++;
          if (! defined $depth_to_n_seen[$got_depth]) {
            $depth_to_n_seen[$got_depth] = $n;
          }
          $depth_to_n_end_seen[$got_depth] = $n;
        }
      }
    }

    if ($path->can('tree_n_to_subheight')
        != Math::PlanePath->can('tree_n_to_subheight')) {
      ### tree_n_to_subheight() vs search downwards ...
      # MyTestHelpers::diag ($mod, ' tree_n_to_subheight()');
      foreach my $n ($n_start .. $n_start+$limit) {
        my $want_height = path_tree_n_to_subheight_by_search($path,$n);
        my $got_height = $path->tree_n_to_subheight($n);
        if (! equal($got_height,$want_height)) {
          &$report ("tree_n_to_subheight($n) got ",$got_height," want ",$want_height);
        }
      }
    }

    if ($path->can('_EXPERIMENTAL__tree_n_to_leafdist')
        # != Math::PlanePath->can('_EXPERIMENTAL__tree_n_to_leafdist')
       ) {
      ### _EXPERIMENTAL__tree_n_to_leafdist() vs search downwards ...
      # MyTestHelpers::diag ($mod, ' _EXPERIMENTAL__tree_n_to_leafdist()');
      foreach my $n ($n_start .. $n_start+$limit) {
        my $want_height = path_tree_n_to_leafdist_by_search($path,$n);
        my $got_height = $path->_EXPERIMENTAL__tree_n_to_leafdist($n);
        if (! equal($got_height,$want_height)) {
          &$report ("_EXPERIMENTAL__tree_n_to_leafdist($n) got ",$got_height," want ",$want_height);
        }
      }
    }

    ### tree_depth_to_n() on depth<0 ...
    foreach my $depth (-2 .. -1) {
      foreach my $method ('tree_depth_to_n','tree_depth_to_n_end') {
        my $n = $path->$method($depth);
        if (defined $n) {
          &$report ("$method($depth) unexpectedly got n=",$n);
        }
      }
      {
        my @ret = $path->tree_depth_to_n_range($depth);
        scalar(@ret) == 0
          or &$report ("tree_depth_to_n_range($depth) not an empty return");
      }
    }

    ### tree_depth_to_n() ...
    if ($is_a_tree) {
      my $n_rows_are_contiguous = path_tree_n_rows_are_contiguous($path);

      foreach my $depth (0 .. $depth_limit) {
        my $n = $path->tree_depth_to_n($depth);
        if (! defined $n) {
          &$report ("tree_depth_to_n($depth) should not be undef");
          next;
        }
        if ($n != int($n)) {
          &$report ("tree_depth_to_n($depth) not an integer: ",$n);
          next;
        }
        if ($n <= $limit) {
          my $want_n = $depth_to_n_seen[$depth];
          if (! defined $want_n || $n != $want_n) {
            &$report ("tree_depth_to_n($depth)=$n but depth_to_n_seen[$depth]=",$want_n);
          }
        }

        my $n_end = $path->tree_depth_to_n_end($depth);
        $n_end >= $n
          or &$report ("tree_depth_to_n_end($depth) $n_end less than tree_depth_to_n() start $n");

        my ($n_range_lo, $n_range_hi) = $path->tree_depth_to_n_range($depth);
        $n_range_lo == $n
          or &$report ("tree_depth_to_n_range($depth) $n_range_lo != tree_depth_to_n() start $n");
        $n_range_hi == $n_end
          or &$report ("tree_depth_to_n_range($depth) $n_range_hi != tree_depth_to_n_end() start $n_end");

        {
          my $got_depth = $path->tree_n_to_depth($n);
          if (! defined $got_depth || $got_depth != $depth) {
            &$report ("tree_depth_to_n($depth)=$n reverse got_depth=",$got_depth);
          }
        }
        {
          my $got_depth = $path->tree_n_to_depth($n-1);
          if (defined $got_depth && $got_depth >= $depth) {
            &$report ("tree_depth_to_n($depth)=$n reverse of n-1 got_depth=",$got_depth);
          }
        }

        {
          my $got_depth = $path->tree_n_to_depth($n_end);
          if (! defined $got_depth || $got_depth != $depth) {
            &$report ("tree_depth_to_n_end($depth)=$n_end reverse n_end got_depth=",$got_depth);
          }
        }
        {
          my $got_depth = $path->tree_n_to_depth($n_end+1);
          if (defined $got_depth && $got_depth <= $depth) {
            &$report ("tree_depth_to_n($depth)=$n reverse of n_end+1 got_depth=",$got_depth);
          }
        }

        if ($n_end <= $limit) {
          my $got_width = $path->tree_depth_to_width($depth);
          my $want_width = $depth_to_width_by_count[$depth] || 0;
          if ($got_width != $want_width) {
            &$report ("tree_depth_to_width($depth)=$got_width but counting want=$want_width");
          }
        }
      }
    }

    ### done mod: $mod
  }
  ok ($good, 1);
}


#------------------------------------------------------------------------------
# path calculations

# Return true if the rows of the tree are numbered contiguously, so each row
# starts immediately following the previous with no overlapping.
sub path_tree_n_rows_are_contiguous {
  my ($path) = @_;
  foreach my $depth (0 .. 10) {
    my $n_end = $path->tree_depth_to_n_end($depth);
    my $n_next = $path->tree_depth_to_n($depth+1);
    if ($n_next != $n_end+1) {
      return 0;
    }
  }
  return 1;
}

# Unused for now.
#
# sub path_tree_depth_to_width_by_count {
#   my ($path, $depth) = @_;
#   ### path_tree_depth_to_width_by_count(): $depth
#   my $width = 0;
#   my ($n_lo, $n_hi) = $path->tree_depth_to_n_range($depth);
#   ### $n_lo
#   ### $n_hi
#   foreach my $n ($n_lo .. $n_hi) {
#     ### d: $path->tree_n_to_depth($n)
#     $width += ($path->tree_n_to_depth($n) == $depth);
#   }
#   ### $width
#   return $width;
# }

sub path_tree_n_to_depth_by_parents {
  my ($path, $n) = @_;
  if ($n < $path->n_start) {
    return undef;
  }
  my $depth = 0;
  for (;;) {
    my $parent_n = $path->tree_n_parent($n);
    last if ! defined $parent_n;
    if ($parent_n >= $n) {
      die "Oops, tree parent $parent_n >= child $n in ", ref $path;
    }
    $n = $parent_n;
    $depth++;
  }
  return $depth;
}

# use Smart::Comments;
use constant SUBHEIGHT_SEARCH_LIMIT => 50;
sub path_tree_n_to_subheight_by_search {
  my ($path, $n, $limit) = @_;

  if ($path->isa('Math::PlanePath::HTree') && is_pow2($n)) {
    return undef;  # infinite
  }

  if (! defined $limit) { $limit = SUBHEIGHT_SEARCH_LIMIT; }
  if ($limit <= 0) {
    return undef;  # presumed infinite
  }
  if (! exists $path->{'path_tree_n_to_subheight_by_search__cache'}->{$n}) {
    my @children = $path->tree_n_children($n);
    my $height = 0;
    foreach my $n_child (@children) {
      my $h = path_tree_n_to_subheight_by_search($path,$n_child,$limit-1);
      if (! defined $h) {
        $height = undef;  # infinite
        last;
      }
      $h++;
      if ($h >= $height) {
        $height = $h;  # new bigger subheight among the children
      }
    }
    ### maximum is: $height
    if (defined $height || $limit >= SUBHEIGHT_SEARCH_LIMIT*4/5) {
      ### set cache: "n=$n  ".($height//'[undef]')
      $path->{'path_tree_n_to_subheight_by_search__cache'}->{$n} = $height;
      ### cache: $path->{'path_tree_n_to_subheight_by_search__cache'}
    }
  }
  ### path_tree_n_to_subheight_by_search(): "n=$n"
  return $path->{'path_tree_n_to_subheight_by_search__cache'}->{$n};


  # my @n = ($n);
  # my $height = 0;
  # my @pending = ($n);
  # for (;;) {
  #   my $n = pop @pending;
  #   @n = map {} @n
  #     or return $height;
  #
  #   if (defined my $h = $path->{'path_tree_n_to_subheight_by_search__cache'}->{$n}) {
  #     return $height + $h;
  #   }
  #   @n = map {$path->tree_n_children($_)} @n
  #     or return $height;
  #   $height++;
  #   if (@n > 200 || $height > 200) {
  #     return undef;  # presumed infinite
  #   }
  # }
}

# no Smart::Comments;
sub path_tree_n_to_leafdist_by_search {
  my ($path, $n, $limit) = @_;
  if (! defined $limit) { $limit = SUBHEIGHT_SEARCH_LIMIT; }
  ### path_tree_n_to_leafdist_by_search(): "n=$n  limit=$limit"

  if ($limit <= 0) {
    return undef;  # presumed infinite
  }
  if (! exists $path->{'path_tree_n_to_leafdist_by_search__cache'}->{$n}) {
    my @children = $path->tree_n_children($n);
    my $leafdist = 0;
    if (@children) {
      my @min;
      foreach my $child_n (@children) {
        my $child_leafdist = path_tree_n_to_leafdist_by_search
          ($path, $child_n, List::Util::min(@min,$limit-1));
        if (defined $child_leafdist) {
          if ($child_leafdist == 0) {
            # child is a leaf, distance to it is 1
            @min = (1);
            last;
          }
          push @min, $child_leafdist+1;
        }
      }
      $leafdist = List::Util::min(@min);
      ### for: "n=$n min of ".join(',',@min)."  children=".join(',',@children)." gives ",$leafdist
    } else {
      ### for: "n=$n is a leaf node"
    }
    if (defined $leafdist || $limit >= SUBHEIGHT_SEARCH_LIMIT*4/5) {
      $path->{'path_tree_n_to_leafdist_by_search__cache'}->{$n} = $leafdist;
    }
  }

  ### path_tree_n_to_leafdist_by_search(): "n=$n"
  return $path->{'path_tree_n_to_leafdist_by_search__cache'}->{$n};
}
# no Smart::Comments;

#------------------------------------------------------------------------------
# generic

sub equal {
  my ($x,$y) = @_;
  return ((! defined $x && ! defined $y)
          || (defined $x && defined $y && $x == $y));
}

use POSIX 'fmod';
sub gcd {
  my ($x,$y) = @_;
  $x = abs($x);
  $y = abs($y);
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  # hack to recognise 1/3 from KochSnowflakes
  if ($x == 1 && $y == 1/3) {
    return $y;
  }

  if ($x == 0) {
    return $y;
  }
  if ($y > $x) {
    $y = fmod($y,$x);
  }
  for (;;) {
    ### assert: $x >= 1
    if ($y == 0) {
      return $x;   # gcd(x,0)=x
    }
    if ($y < 0.00001) {
      return 0;
    }
    ($x,$y) = ($y, fmod($x,$y));
  }
}

sub is_pow2 {
  my ($n) = @_;
  my ($pow,$exp) = round_down_pow ($n, 2);
  return ($n == $pow);
}

sub coderef_is_const {
  my ($coderef) = @_;
  # FIXME: is not quite right?  Is XSUBANY present on ALIAS: xsubs too?
  require B;
  return defined(B::svref_2object(\&coderef_is_const)->XSUBANY);
}
CHECK {
  # my $coderef_is_const_check = 1;
  use constant coderef_is_const_check => 1;
  coderef_is_const(\&coderef_is_const_check) or die;
}

use constant pi => atan2(1,0)*4;

# $a and $b are arrayrefs [$dx,$dy]
# Return an order +ve,0,-ve between them, first by angle then by length.
sub dxdy_cmp {
  my ($a_dx,$a_dy, $b_dx,$b_dy) = @_;
  return dxdy_cmp_angle($a_dx,$a_dy, $b_dx,$b_dy) || dxdy_cmp_length($a_dx,$a_dy, $b_dx,$b_dy) || 0;
}
sub dxdy_cmp_angle {
  my ($a_dx,$a_dy, $b_dx,$b_dy) = @_;
  my $a_angle = atan2($a_dy,$a_dx);
  my $b_angle = atan2($b_dy,$b_dx);
  if ($a_angle < 0) { $a_angle += 2*pi(); }
  if ($b_angle < 0) { $b_angle += 2*pi(); }
  return $a_angle <=> $b_angle;
}
sub dxdy_cmp_length {
  my ($a_dx,$a_dy, $b_dx,$b_dy) = @_;
  return ($a_dx**2 + $a_dy**2
          <=> $b_dx**2 + $b_dy**2);
}

sub path_n_to_LSR_with_rounding {
  my ($path, $n) = @_;
  my ($prev_dx,$prev_dy) = $path->n_to_dxdy($n - $path->arms_count)
    or return 98;
  my ($dx,$dy)           = $path->n_to_dxdy($n)
    or return 99;
  my $LSR = $dy*$prev_dx - $dx*$prev_dy;
  if (abs($LSR) < 1e-10) { $LSR = 0; }
  $LSR = ($LSR <=> 0);  # 1,undef,-1
  # print "path_n_to_LSR   dxdy $prev_dx,$prev_dy then $dx,$dy  is LSR=$LSR\n";
  return $LSR;
}

exit 0;
