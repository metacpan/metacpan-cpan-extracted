#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2018, 2019, 2020 Kevin Ryde

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


# Crib notes:
#
# In perl 5.8.4 "BigInt != BigRat" doesn't work, must have it other way
# around as "BigRat != BigInt" so get the BigRat equality testing code.
# Symptom is "uninitialized" warnings.
#


use 5.004;
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
# use Smart::Comments '###';


my $test_count = (tests => 484)[1];
plan tests => $test_count;

if (! eval { require Math::BigRat; 1 }) {
  MyTestHelpers::diag ('skip due to Math::BigRat not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('due to no Math::BigRat', 1, 1);
  }
  exit 0;
}
MyTestHelpers::diag ('Math::BigRat version ', Math::BigRat->VERSION);
if (! Math::BigRat->can('as_float')) {
  MyTestHelpers::diag ('skip due to Math::BigRat->as_float method not available');
  foreach (1 .. $test_count) {
    skip ('due to no as_float()', 1, 1);
  }
  exit 0;
}
{
  my $f = Math::BigRat->new('-1/2');
  my $int = int($f);
  if ($int == 0) {
    MyTestHelpers::diag ('BigRat int(-1/2)==0, good');
  } else {
    MyTestHelpers::diag ("BigRat has int(-1/2) != 0 dodginess: value is '$int'");
  }
}

require Math::BigInt;
MyTestHelpers::diag ('Math::BigInt version ', Math::BigInt->VERSION);
{
  my $n = Math::BigInt->new(2) ** 256;
  my $int = int($n);
  if (! ref $int) {
    MyTestHelpers::diag ('skip due to Math::BigInt no "int" operator');
    foreach (1 .. $test_count) {
      skip ('due to no Math::BigInt int() operator', 1, 1);
    }
    exit 0;
  }
}

# doesn't help sqrt(), slows down blog()
#
# require Math::BigFloat;
# Math::BigFloat->precision(-2000);  # digits right of decimal point


#------------------------------------------------------------------------------
# Diagonals

{
  require Math::PlanePath::Diagonals;
  my $path = Math::PlanePath::Diagonals->new;

  {
    my $x = Math::BigRat->new(10);
    my $n = ($x+1)*($x+2)/2;  # triangular numbers on Y=0 horizontal
    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x == $x, 1, "got x=$got_x want $x");
    ok ($got_y == 0,  1, "got y=$got_y want 0");

    my $got_n = $path->xy_to_n($x,0);
    ok ($got_n == $n, 1);
  }
  {
    my $x = Math::BigRat->new(2) ** 256 - 1;
    my $n = ($x+1)*($x+2)/2;  # triangular numbers on Y=0 horizontal

    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x == $x, 1, "got x=$got_x want $x");
    ok ($got_y == 0,  1, "got y=$got_y want 0");

    my $got_n = $path->xy_to_n($x,0);
    ok ($got_n == $n, 1);
  }
  {
    my $x = Math::BigRat->new(2) ** 128 - 1;
    my $n = ($x+1)*($x+2)/2;  # Y=0 horizontal

    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x == $x, 1);
    ok ($got_y == 0, 1);

    my $got_n = $path->xy_to_n($x,0);
    ok ($got_n == $n, 1);
  }
  {
    my $y = Math::BigRat->new(2) ** 128 - 1;
    my $n = $y*($y+1)/2 + 1;  # X=0 vertical

    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x == 0, 1);
    ok ($got_y == $y, 1);
 
    my $got_n = $path->xy_to_n(0,$y);
    ok ($got_n, $n);
  }

  {
    my $n = Math::BigRat->new(-1);
    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x, undef);
    ok ($got_y, undef);
  }
  {
    my $n = Math::BigRat->new(0.5);
    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok (!! $got_x->isa('Math::BigRat'), 1);
    ok (!! $got_y->isa('Math::BigRat'), 1);
    ok ($got_x == -0.5, 1);
    ok ($got_y == 0.5, 1);
  }
}

#------------------------------------------------------------------------------
# MultipleRings

{
  require Math::PlanePath::MultipleRings;
  my $width = 5;
  my $path = Math::PlanePath::MultipleRings->new (step => 6);

  {
    my $n = Math::BigRat->new(23);
    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok (!! (ref $got_x && $got_x->isa('Math::BigFloat')), 1,
       "MultipleRings raise BigRat to BigFloat");
    ok ($got_x > 0 && $got_x < 1,
        1,
       "MultipleRings n_to_xy($n) got_x $got_x");
    ok ($got_y > 2.5 && $got_y < 3.1,
        1,
       "MultipleRings n_to_xy($n) got_y $got_y");
  }
}

#------------------------------------------------------------------------------
# round_nearest()

use Math::PlanePath::Base::Generic
  'round_nearest';
ok (round_nearest(Math::BigRat->new('-7/4')) == -2, 1);
ok (round_nearest(Math::BigRat->new('-3/2')) == -1,  1);
ok (round_nearest(Math::BigRat->new('-5/4')) == -1,  1);

ok (round_nearest(Math::BigRat->new('-3/4')) == -1, 1);
ok (round_nearest(Math::BigRat->new('-1/2')) == 0,  1);
ok (round_nearest(Math::BigRat->new('-1/4')) == 0,  1);

ok (round_nearest(Math::BigRat->new('1/4')) == 0,  1);
ok (round_nearest(Math::BigRat->new('5/4')) == 1,  1);
ok (round_nearest(Math::BigRat->new('3/2')) == 2,  1);
ok (round_nearest(Math::BigRat->new('7/4')) == 2,  1);
ok (round_nearest(Math::BigRat->new('2'))   == 2,  1);

#------------------------------------------------------------------------------
# floor()

use Math::PlanePath::Base::Generic
  'floor';
ok (floor(Math::BigRat->new('-7/4')) == -2,  1);
ok (floor(Math::BigRat->new('-3/2')) == -2,  1);
ok (floor(Math::BigRat->new('-5/4')) == -2,  1);

ok (floor(Math::BigRat->new('-3/4')) == -1,  1);
ok (floor(Math::BigRat->new('-1/2')) == -1,  1);
ok (floor(Math::BigRat->new('-1/4')) == -1,  1);

ok (floor(Math::BigRat->new('1/4')) == 0,  1);
ok (floor(Math::BigRat->new('3/4')) == 0,  1);
ok (floor(Math::BigRat->new('5/4')) == 1,  1);
ok (floor(Math::BigRat->new('3/2')) == 1,  1);
ok (floor(Math::BigRat->new('7/4')) == 1,  1);
ok (floor(Math::BigRat->new('2'))   == 2,  1);


#------------------------------------------------------------------------------
# CoprimeColumns

{
  require Math::PlanePath::CoprimeColumns;
  my $path = Math::PlanePath::CoprimeColumns->new;

  {
    my $n = Math::BigRat->new('-2/3');
    my @ret = $path->n_to_xy($n);
    ok (scalar(@ret), 0);
  }
  {
    my $n = Math::BigRat->new(0);
    my $want_x = 1;
    my $want_y = 1;

    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x == $want_x, 1, "got $got_x want $want_x");
    ok ($got_y == $want_y);

    my $got_n = $path->xy_to_n($want_x,$want_y);
    ok ($got_n == 0, 1);
  }
  # pending int(-1/2)==0 dodginess
  # {
  #   my $n = Math::BigRat->new('-1/3');
  #   my $want_x = 1;
  #   my $want_y = Math::BigRat->new('1/3');
  # 
  #   my ($got_x,$got_y) = $path->n_to_xy($n);
  #   ok ($got_x == $want_x, 1, "got $got_x want $want_x");
  #   ok ($got_y == $want_y);
  # 
  #   my $got_n = $path->xy_to_n($want_x,$want_y);
  #   ok ($got_n == 0, 1);
  # }
  {
    my $n = Math::BigRat->new('1/2');
    my $want_x = 2;
    my $want_y = Math::BigRat->new('1/2');

    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x == $want_x, 1, "got $got_x want $want_x");
    ok ($got_y == $want_y);

    my $got_n = $path->xy_to_n($want_x,$want_y);
    ok ($got_n == 1, 1);
  }
}


#------------------------------------------------------------------------------
# DiagonalRationals

{
  require Math::PlanePath::DiagonalRationals;
  my $path = Math::PlanePath::DiagonalRationals->new;

  {
    my $n = Math::BigRat->new('1/3');
    my @ret = $path->n_to_xy($n);
    ok (scalar(@ret), 0);
  }
  {
    my $n = Math::BigRat->new('1/2');
    my $want_x = Math::BigRat->new('1/2');
    my $want_y = Math::BigRat->new('3/2');

    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x == $want_x, 1,
        "DiagonalRationals n_to_xy() n=$n, got X=$got_x want X=$want_x");
    ok ($got_y == $want_y, 1,
        "DiagonalRationals n_to_xy() n=$n, got Y=$got_y want Y=$want_y");

    # my $got_n = $path->xy_to_n($want_x,$want_y);
    # ok (defined $got_n && $got_n == 1, 1,
    #     'DiagonalRationals xy_to_n($want_x,$want_y) from 1/2');
  }

  {
    #
    #      | 1+1/2
    #      |    \
    #      |     \
    #  Y=1 |      1
    #      |       \
    #      |        1+1/3
    #      |         \
    #      |          1+1/2-eps
    #      |
    #      +---------------
    #             ^
    #            X=1
    my $n = Math::BigRat->new('4/3');
    my $want_x = Math::BigRat->new('4/3');
    my $want_y = Math::BigRat->new('2/3');

    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x == $want_x, 1,
        "DiagonalRationals n_to_xy() from 4/3, X got $got_x want $want_x");
    ok ($got_y == $want_y, 1,
        "DiagonalRationals n_to_xy() from 4/3, Y got $got_y want $want_y");

    my $got_n = $path->xy_to_n($want_x,$want_y);
    ok ($got_n == 1, 1, 'DiagonalRationals xy_to_n($want_x,$want_y) from 4/3');
  }
}

#------------------------------------------------------------------------------
# Rows

{
  require Math::PlanePath::Rows;
  my $width = 5;
  my $path = Math::PlanePath::Rows->new (width => $width);

  {
    my $y = Math::BigRat->new(2) ** 128;
    my $x = 4;
    my $n = $y*$width + $x + 1;

    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ($got_x == $x, 1, "got $got_x want $x");
    ok ($got_y == $y);

    my $got_n = $path->xy_to_n($x,$y);
    ok ($got_n == $n, 1);
  }
  {
    my $n = Math::BigRat->new('4/3');
    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ("$got_x", '1/3');
    ok ($got_y == 0, 1);
  }
  {
    my $n = Math::BigRat->new('4/3') + 15;
    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ("$got_x", '1/3');
    ok ($got_y == 3, 1);
  }
  {
    my $n = Math::BigRat->new('4/3') - 15;
    my ($got_x,$got_y) = $path->n_to_xy($n);
    ok ("$got_x", '1/3');
    ok ($got_y == -3, 1);
  }
}

#------------------------------------------------------------------------------
# PeanoCurve

require Math::PlanePath::PeanoCurve;
{
  my $path = Math::PlanePath::PeanoCurve->new;

  require Math::BigRat;
  my $n = Math::BigRat->new(9) ** 128 + Math::BigRat->new('4/3');
  my $want_x = Math::BigRat->new(3) ** 128 + Math::BigRat->new('4/3');
  my $want_y = Math::BigRat->new(3) ** 128 - 1;

  my ($got_x,$got_y) = $path->n_to_xy($n);
  ok ($got_x, $want_x);
  ok ($got_y, $want_y);
}

#------------------------------------------------------------------------------
# ZOrderCurve

require Math::PlanePath::ZOrderCurve;
{
  my $path = Math::PlanePath::ZOrderCurve->new;

  require Math::BigRat;
  my $n = Math::BigRat->new(4) ** 128 + Math::BigRat->new('1/3');
  $n->isa('Math::BigRat') || die "Oops, n not a BigRat";
  my $want_x = Math::BigRat->new(2) ** 128 + Math::BigRat->new('1/3');
  my $want_y = 0;

  my ($got_x,$got_y) = $path->n_to_xy($n);
  ok ($got_x, $want_x);
  ok ($got_y, $want_y);
}

#------------------------------------------------------------------------------
# round_down_pow()

use Math::PlanePath::Base::Digits 'round_down_pow';
{
  my $orig = Math::BigRat->new(3) ** 128 + Math::BigRat->new('1/7');
  my $n    = Math::BigRat->new(3) ** 128 + Math::BigRat->new('1/7');
  my ($pow,$exp) = round_down_pow($n,3);

  ok ($n, $orig);
  ok ($pow, Math::BigRat->new(3) ** 128);
  ok ($exp, 128);
}
{
  my $orig = Math::BigRat->new(3) ** 128;
  my $n    = Math::BigRat->new(3) ** 128;
  my ($pow,$exp) = round_down_pow($n,3);
  
  ok ($n, $orig);
  ok ($pow, Math::BigRat->new(3) ** 128);
  ok ($exp, 128);
}

#------------------------------------------------------------------------------

my @modules = (
               'HilbertSides',
               'HilbertCurve',
               'HilbertSpiral',

               'WythoffPreliminaryTriangle',
               'WythoffArray',
               'PowerArray',
               'PowerArray,radix=3',
               'PowerArray,radix=4',

               'AztecDiamondRings',     # but not across ring end
               'PyramidSpiral',

               'CfracDigits,radix=1',
               'CfracDigits',
               'CfracDigits,radix=3',
               'CfracDigits,radix=4',
               'CfracDigits,radix=10',
               'CfracDigits,radix=37',

               'ChanTree',
               'ChanTree,k=2',
               'ChanTree,k=4',
               'ChanTree,k=5',
               'ChanTree,k=7',
               'ChanTree,reduced=1',
               'ChanTree,reduced=1,k=2',
               'ChanTree,reduced=1,k=4',
               'ChanTree,reduced=1,k=5',
               'ChanTree,reduced=1,k=7',

               'RationalsTree',
               'RationalsTree,tree_type=L',
               'RationalsTree,tree_type=HCS',
               'FractionsTree',

               'DekkingCurve',
               'DekkingCentres',

               'QuintetCurve',
               'QuintetCurve,arms=2',
               'QuintetCurve,arms=3',
               'QuintetCurve,arms=4',
               'QuintetCentres',
               'QuintetCentres,arms=2',
               'QuintetCentres,arms=3',
               'QuintetCentres,arms=4',

               'PyramidRows',
               'PyramidRows,step=0',
               'PyramidRows,step=1',
               'PyramidRows,step=3',
               'PyramidRows,step=37',

               'PyramidRows,align=right',
               'PyramidRows,align=right,step=0',
               'PyramidRows,align=right,step=1',
               'PyramidRows,align=right,step=3',
               'PyramidRows,align=right,step=37',

               'PyramidRows,align=left',
               'PyramidRows,align=left,step=0',
               'PyramidRows,align=left,step=1',
               'PyramidRows,align=left,step=3',
               'PyramidRows,align=left,step=37',

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

               'AlternatePaperMidpoint',
               'AlternatePaperMidpoint,arms=2',
               'AlternatePaperMidpoint,arms=3',
               'AlternatePaperMidpoint,arms=4',
               'AlternatePaperMidpoint,arms=5',
               'AlternatePaperMidpoint,arms=6',
               'AlternatePaperMidpoint,arms=7',
               'AlternatePaperMidpoint,arms=8',

               'AlternatePaper',
               'AlternatePaper,arms=2',
               'AlternatePaper,arms=3',
               'AlternatePaper,arms=4',
               'AlternatePaper,arms=5',
               'AlternatePaper,arms=6',
               'AlternatePaper,arms=7',
               'AlternatePaper,arms=8',

               'Diagonals',
               'Diagonals,direction=up',
               'DiagonalsOctant',
               'DiagonalsOctant,direction=up',
               'DiagonalsAlternating',

               'AlternateTerdragon',
               'AlternateTerdragon,arms=1',
               'AlternateTerdragon,arms=2',
               'AlternateTerdragon,arms=6',

               'TerdragonMidpoint',
               'TerdragonMidpoint,arms=1',
               'TerdragonMidpoint,arms=2',
               'TerdragonMidpoint,arms=6',

               'TerdragonCurve',
               'TerdragonCurve,arms=1',
               'TerdragonCurve,arms=2',
               'TerdragonCurve,arms=6',

               'TerdragonRounded',
               'TerdragonRounded,arms=1',
               'TerdragonRounded,arms=2',
               'TerdragonRounded,arms=6',

               'CCurve',

               'R5DragonMidpoint',
               'R5DragonMidpoint,arms=2',
               'R5DragonMidpoint,arms=3',
               'R5DragonMidpoint,arms=4',
               'R5DragonCurve',
               'R5DragonCurve,arms=2',
               'R5DragonCurve,arms=3',
               'R5DragonCurve,arms=4',

               'ImaginaryHalf',
               'ImaginaryBase',
               'CubicBase',

               'GrayCode',

               'WunderlichSerpentine',
               'WunderlichSerpentine,serpentine_type=100_000_000',
               'WunderlichSerpentine,serpentine_type=000_000_001',
               'WunderlichSerpentine,radix=2',
               'WunderlichSerpentine,radix=4',
               'WunderlichSerpentine,radix=5,serpentine_type=coil',

               'CretanLabyrinth',

               'OctagramSpiral',
               'AnvilSpiral',
               'AnvilSpiral,wider=1',
               'AnvilSpiral,wider=2',
               'AnvilSpiral,wider=9',
               'AnvilSpiral,wider=17',

               'AR2W2Curve',
               'AR2W2Curve,start_shape=D2',
               'AR2W2Curve,start_shape=B2',
               'AR2W2Curve,start_shape=B1rev',
               'AR2W2Curve,start_shape=D1rev',
               'AR2W2Curve,start_shape=A2rev',
               'BetaOmega',
               'KochelCurve',
               'CincoCurve',

               'LTiling',
               'LTiling,L_fill=ends',
               'LTiling,L_fill=all',
               'MPeaks',   # but not across gap
               'WunderlichMeander',
               'FibonacciWordFractal',
               # 'CornerReplicate',    # not defined yet
               'DigitGroups',
               'PeanoCurve',
               'PeanoDiagonals',
               'ZOrderCurve',
               
               'HIndexing',
               'SierpinskiCurve',
               'SierpinskiCurveStair',
               'DiamondArms',
               'SquareArms',
               'HexArms',
               
               # 'UlamWarburton',         # not really defined yet
               # 'UlamWarburtonQuarter',  # not really defined yet
               'CellularRule54',      # but not across gap
               # 'CellularRule57',           # but not across gap
               # 'CellularRule57,mirror=1',  # but not across gap
               'CellularRule190',     # but not across gap
               'CellularRule190,mirror=1',   # but not across gap
               
               'Rows',
               'Columns',
               
               'SquareSpiral',
               'DiamondSpiral',
               'PentSpiral',
               'PentSpiralSkewed',
               'HexSpiral',
               'HexSpiralSkewed',
               'HeptSpiralSkewed',
               'TriangleSpiral',
               'TriangleSpiralSkewed',
               'TriangleSpiralSkewed,skew=right',
               'TriangleSpiralSkewed,skew=up',
               'TriangleSpiralSkewed,skew=down',
               
               # 'SacksSpiral',         # sin/cos
               # 'TheodorusSpiral',     # counting by N
               # 'ArchimedeanChords',   # counting by N
               # 'VogelFloret',         # sin/cos
               'KnightSpiral',
               
               'SierpinskiArrowheadCentres',
               'SierpinskiArrowheadCentres,align=right',
               'SierpinskiArrowheadCentres,align=left',
               'SierpinskiArrowheadCentres,align=diagonal',

               'SierpinskiArrowhead',
               'SierpinskiArrowhead,align=right',
               'SierpinskiArrowhead,align=left',
               'SierpinskiArrowhead,align=diagonal',

               # 'SierpinskiTriangle',  # fracs not really defined yet
               'QuadricCurve',
               'QuadricIslands',
               
               'DragonRounded',
               'DragonMidpoint',
               'DragonCurve',
               
               'KochSquareflakes',
               'KochSnowflakes',
               'KochCurve',
               'KochPeaks',
               
               'FlowsnakeCentres',
               'GosperReplicate',
               'GosperSide',
               'GosperIslands',
               'Flowsnake',
               
               # 'DivisibleColumns', # counting by N
               # 'DivisibleColumns,divisor_type=proper',
               # 'CoprimeColumns',   # counting by N
               # 'DiagonalRationals',# counting by N
               # 'GcdRationals',     # counting by N
               # 'GcdRationals,pairs_order=rows_reverse',
               # 'GcdRationals,pairs_order=diagonals_down',
               # 'GcdRationals,pairs_order=diagonals_up',
               # 'FactorRationals',  # counting by N
               # 'TriangularHypot',  # counting by N
               # 'TriangularHypot,points=odd',
               # 'TriangularHypot,points=all',
               # 'TriangularHypot,points=hex',
               # 'TriangularHypot,points=hex_rotated',
               # 'TriangularHypot,points=hex_centred',
               'PythagoreanTree',
               
               # 'Hypot',            # searching by N
               # 'HypotOctant',      # searching by N
               # 'PixelRings',       # searching by N
               # 'FilledRings',      # searching by N
               # 'MultipleRings',    # sin/cos, maybe
               
               'QuintetReplicate',
               
               'SquareReplicate',
               'ComplexPlus',
               'ComplexMinus',
               'ComplexRevolving',
               
               # 'File',  # not applicable
               'Corner',
               'PyramidSides',
               'Staircase',
               'StaircaseAlternating',
               'StaircaseAlternating,end_type=square',
              );
my @classes = map {"Math::PlanePath::$_"} @modules;

sub module_parse {
  my ($mod) = @_;
  my ($class, @parameters) = split /,/, $mod;
  return ("Math::PlanePath::$class",
          map {/(.*?)=(.*)/ or die; ($1 => $2)} @parameters);
}

foreach my $module (@modules) {
  ### $module
  my ($class, %parameters) = module_parse($module);
  eval "require $class" or die;
  
  my $path = $class->new (width => 23,
                          height => 17);
  my $arms = $path->arms_count;
  
  my $n = Math::BigRat->new(2) ** 256 + 3;
  if ($path->isa('Math::PlanePath::CellularRule190')) {
    $n += 1; # not across gap
  }
  my $frac = Math::BigRat->new('1/3');
  my $n_frac = $frac + $n;
  my $orig = $n_frac->copy;
  
  my ($x1,$y1) = $path->n_to_xy($n);
  ### xy1: "$x1,$y1"
  my ($x2,$y2) = $path->n_to_xy($n+$arms);
  ### xy2: "$x2,$y2"
  
  my $dx = $x2 - $x1;
  my $dy = $y2 - $y1;
  ### dxy: "$dx, $dy"

  my $want_x = $frac * Math::BigRat->new ($dx) + $x1;
  my $want_y = $frac * Math::BigRat->new ($dy) + $y1;

  my ($x_frac,$y_frac) = $path->n_to_xy($n_frac);
  ### xy frac: "$x_frac, $y_frac"

  ok ("$x_frac", "$want_x", "$module arms=$arms X frac=$frac dxdy=$dx,$dy arms=$arms");
  ok ("$y_frac", "$want_y", "$module arms=$arms Y frac=$frac dxdy=$dx,$dy arms=$arms");
}

exit 0;
