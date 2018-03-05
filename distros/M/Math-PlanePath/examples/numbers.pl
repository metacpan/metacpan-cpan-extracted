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


# Usage: perl numbers.pl CLASS...
#        perl numbers.pl all
#
# Print the given path CLASS or classes as N numbers in a grid.  Eg.
#
#     perl numbers.pl SquareSpiral DiamondSpiral
#
# Parameters to the class can be given as
#
#     perl numbers.pl SquareSpiral,wider=4
#
# With option "all" print all classes and a selection of their parameters,
# per the table in the code below
#
#     perl numbers.pl all
#
# See square-numbers.pl for a simpler program designed just for the
# SquareSpiral.  The code here tries to adapt itself to the tty width and
# stops when the width of the numbers to be displayed would be wider than
# the tty.
#
# Stopping when N goes outside the tty means that just the first say 99 or
# so N values will be shown.  There's often other bigger N within the X,Y
# grid region, but the first few N show how the path begins, without
# clogging up the output.
#
# The origin 0,0 is kept in the middle of the output, horizontally, to help
# see how much is on each side and to make multiple paths printed line up
# such as the "all" option.  Vertically only as many rows as necessary are
# printed.
#
# Paths with fractional X,Y positions like SacksSpiral or VogelFloret are
# rounded to character positions.  There's some hard-coded fudge factors to
# try to make them come out nicely.
#
# When an X,Y position is visited more than once multiple N's are shown with
# a comma like "9,24".  This can happen for example in the DragonCurve where
# points are visited twice, or when rounding gives the same X,Y for a few
# initial points such as in KochSquareflakes.
#

use 5.004;
use strict;
use POSIX ();
use List::Util 'min', 'max';

my $width = 79;
my $height = 23;

# use Term::Size if available
# chars() can return 0 for unknown size, ignore that
if (eval { require Term::Size }) {
  my ($term_width, $term_height) = Term::Size::chars();
  if ($term_width)  { $width = $term_width - 1; }
  if ($term_height) { $height = $term_height - 1; }
}

if (! @ARGV) {
  push @ARGV, 'HexSpiral';  # default class to print if no args
}

my @all_classes = ('SquareSpiral',
                   'SquareSpiral,wider=9',
                   'DiamondSpiral',
                   'PentSpiral',
                   'PentSpiralSkewed',
                   'HexSpiral',
                   'HexSpiral,wider=3',
                   'HexSpiralSkewed',
                   'HexSpiralSkewed,wider=5',
                   'HeptSpiralSkewed',
                   'AnvilSpiral',
                   'AnvilSpiral,wider=3',
                   'OctagramSpiral',

                   'PyramidSpiral',
                   'PyramidRows',
                   'PyramidRows,step=5',
                   'PyramidRows,align=right',
                   'PyramidRows,align=left,step=4',

                   'PyramidSides',
                   'CellularRule,rule=30',
                   'CellularRule,rule=73',
                   'CellularRule54',
                   'CellularRule57',
                   'CellularRule57,mirror=1',
                   'CellularRule190',
                   'CellularRule190,mirror=1',
                   'TriangleSpiral',
                   'TriangleSpiralSkewed',
                   'TriangleSpiralSkewed,skew=right',
                   'TriangleSpiralSkewed,skew=up',
                   'TriangleSpiralSkewed,skew=down',

                   'Diagonals',
                   'Diagonals,direction=up',
                   'DiagonalsAlternating',
                   'DiagonalsOctant',
                   'DiagonalsOctant,direction=up',
                   'Staircase',
                   'StaircaseAlternating',
                   'StaircaseAlternating,end_type=square',
                   'Corner',
                   'Corner,wider=5',
                   'KnightSpiral',
                   'CretanLabyrinth',

                   'SquareArms',
                   'DiamondArms',
                   'HexArms',
                   'GreekKeySpiral',
                   'GreekKeySpiral,turns=4',
                   'GreekKeySpiral,turns=1',

                   'AztecDiamondRings',
                   'MPeaks',

                   'SacksSpiral',
                   'VogelFloret',
                   'ArchimedeanChords',
                   'TheodorusSpiral',
                   'MultipleRings',
                   'MultipleRings,step=14',
                   'PixelRings',
                   'FilledRings',
                   'Hypot',
                   'Hypot,points=even',
                   'Hypot,points=odd',
                   'HypotOctant',
                   'HypotOctant,points=even',
                   'HypotOctant,points=odd',

                   'TriangularHypot',
                   'TriangularHypot,points=odd',
                   'TriangularHypot,points=all',
                   'TriangularHypot,points=hex',
                   'TriangularHypot,points=hex_rotated',
                   'TriangularHypot,points=hex_centred',

                   'Rows',
                   'Columns',
                   'UlamWarburton',
                   'UlamWarburton,parts=2',
                   'UlamWarburton,parts=1',
                   'UlamWarburton,parts=octant',
                   'UlamWarburton,parts=octant_up',
                   'UlamWarburtonQuarter',
                   'UlamWarburtonQuarter,parts=octant',
                   'UlamWarburtonQuarter,parts=octant_up',

                   'PeanoCurve',
                   'PeanoCurve,radix=5',
                   'WunderlichSerpentine',
                   'WunderlichSerpentine,serpentine_type=coil',
                   'WunderlichSerpentine,radix=5,serpentine_type=01001_01110_01000_11111_00010',
                   'WunderlichMeander',

                   'HilbertCurve',
                   'HilbertSides',
                   'HilbertSpiral',

                   'ZOrderCurve',
                   'ZOrderCurve,radix=5',

                   'GrayCode',
                   'GrayCode,apply_type=Ts',
                   'GrayCode,radix=4',

                   'BetaOmega',
                   'AR2W2Curve',
                   'AR2W2Curve,start_shape=D2',
                   'AR2W2Curve,start_shape=B2',
                   'AR2W2Curve,start_shape=B1rev',
                   'AR2W2Curve,start_shape=D1rev',
                   'AR2W2Curve,start_shape=A2rev',
                   'KochelCurve',
                   'DekkingCurve',
                   'DekkingCurve,arms=2',
                   'DekkingCurve,arms=3',
                   'DekkingCurve,arms=4',
                   'DekkingCentres',
                   'CincoCurve',

                   'ImaginaryBase',
                   'ImaginaryBase,radix=4',

                   'ImaginaryHalf',
                   'ImaginaryHalf,radix=4',
                   'ImaginaryHalf,digit_order=XXY',
                   'ImaginaryHalf,digit_order=YXX',
                   'ImaginaryHalf,digit_order=XnXY',
                   'ImaginaryHalf,digit_order=XnYX',
                   'ImaginaryHalf,digit_order=YXnX',

                   'CubicBase',
                   'CubicBase,radix=4',
                   'SquareReplicate',
                   'SquareReplicate,numbering_type=rotate-4',
                   'SquareReplicate,numbering_type=rotate-8',
                   'CornerReplicate',
                   'LTiling',
                   'LTiling,L_fill=ends',
                   'LTiling,L_fill=all',
                   'DigitGroups',
                   'FibonacciWordFractal',

                   'Flowsnake',
                   'Flowsnake,arms=3',
                   'FlowsnakeCentres',
                   'FlowsnakeCentres,arms=3',
                   'GosperReplicate',
                   'GosperReplicate,numbering_type=rotate',
                   'GosperIslands',
                   'GosperSide',

                   'QuintetCurve',
                   'QuintetCurve,arms=4',
                   'QuintetCentres',
                   'QuintetReplicate',
                   'QuintetReplicate,numbering_type=rotate',

                   'KochCurve',
                   'KochPeaks',
                   'KochSnowflakes',
                   'KochSquareflakes',
                   'KochSquareflakes,inward=1',
                   'QuadricCurve',
                   'QuadricIslands',

                   'SierpinskiCurve',
                   'SierpinskiCurve,arms=8',
                   'SierpinskiCurveStair',
                   'SierpinskiCurveStair,arms=2',
                   'SierpinskiCurveStair,diagonal_length=4',
                   'HIndexing',

                   'SierpinskiTriangle',
                   'SierpinskiTriangle,align=right',
                   'SierpinskiTriangle,align=left',
                   'SierpinskiTriangle,align=diagonal',

                   'SierpinskiArrowhead',
                   'SierpinskiArrowhead,align=right',
                   'SierpinskiArrowhead,align=left',
                   'SierpinskiArrowhead,align=diagonal',

                   'SierpinskiArrowheadCentres',
                   'SierpinskiArrowheadCentres,align=right',
                   'SierpinskiArrowheadCentres,align=left',
                   'SierpinskiArrowheadCentres,align=diagonal',

                   'DragonCurve',
                   'DragonCurve,arms=4',
                   'DragonRounded',
                   'DragonRounded,arms=4',
                   'DragonMidpoint',
                   'DragonMidpoint,arms=2',
                   'DragonMidpoint,arms=3',
                   'DragonMidpoint,arms=4',
                   'AlternatePaper',
                   'AlternatePaper,arms=2',
                   'AlternatePaper,arms=8',
                   'AlternatePaperMidpoint',
                   'AlternatePaperMidpoint,arms=2',
                   'AlternatePaperMidpoint,arms=8',
                   'CCurve',
                   'TerdragonCurve',
                   'TerdragonCurve,arms=6',
                   'TerdragonRounded',
                   'TerdragonRounded,arms=6',
                   'TerdragonMidpoint',
                   'TerdragonMidpoint,arms=6',
                   'AlternateTerdragon',
                   'AlternateTerdragon,arms=6',
                   'R5DragonCurve',
                   'R5DragonCurve,arms=4',
                   'R5DragonMidpoint',
                   'R5DragonMidpoint,arms=2',
                   'R5DragonMidpoint,arms=3',
                   'R5DragonMidpoint,arms=4',
                   'ComplexPlus',
                   'ComplexPlus,realpart=2',
                   'ComplexMinus',
                   'ComplexMinus,realpart=2',
                   'ComplexRevolving',

                   'PythagoreanTree,tree_type=UAD',
                   'PythagoreanTree,tree_type=UAD,coordinates=AC',
                   'PythagoreanTree,tree_type=UAD,coordinates=BC',
                   'PythagoreanTree,tree_type=UAD,coordinates=PQ',
                   'PythagoreanTree,tree_type=UAD,coordinates=SM',
                   'PythagoreanTree,tree_type=UAD,coordinates=SC',
                   'PythagoreanTree,tree_type=UAD,coordinates=MC',
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

                   'DiagonalRationals',
                   'DiagonalRationals,direction=up',
                   'CoprimeColumns',
                   'FactorRationals',
                   'GcdRationals',
                   'GcdRationals,pairs_order=rows_reverse',
                   'GcdRationals,pairs_order=diagonals_down',
                   'GcdRationals,pairs_order=diagonals_up',
                   'RationalsTree,tree_type=SB',
                   'RationalsTree,tree_type=CW',
                   'RationalsTree,tree_type=AYT',
                   'RationalsTree,tree_type=HCS',
                   'RationalsTree,tree_type=Bird',
                   'RationalsTree,tree_type=Drib',
                   'RationalsTree,tree_type=L',
                   'FractionsTree',
                   'ChanTree',
                   'ChanTree,k=4',
                   'ChanTree,k=5',
                   'ChanTree,k=7',
                   'ChanTree,k=8',

                   'CfracDigits',
                   'CfracDigits,radix=3',
                   'CfracDigits,radix=4',
                   'CfracDigits,radix=1',

                   'DivisibleColumns',
                   'DivisibleColumns,divisor_type=proper',

                   'WythoffArray',
                   'WythoffPreliminaryTriangle',
                   'PowerArray',
                   'PowerArray,radix=3',
                   'PowerArray,radix=4',

                   # in separate Math-PlanePath-Toothpick

                   '*ToothpickTree',
                   '*ToothpickTree,parts=3',
                   '*ToothpickTree,parts=2',
                   '*ToothpickTree,parts=1',
                   '*ToothpickTree,parts=octant',
                   '*ToothpickTree,parts=octant_up',
                   '*ToothpickTree,parts=wedge',
                   
                   '*ToothpickReplicate',
                   '*ToothpickReplicate,parts=3',
                   '*ToothpickReplicate,parts=2',
                   '*ToothpickReplicate,parts=1',

                   '*ToothpickUpist',
                   '*ToothpickSpiral',
                   
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
                   '*LCornerTree,parts=diagonal',
                   '*LCornerTree,parts=diagonal-1',
                   
                   '*LCornerReplicate',

                   '*OneOfEight',
                   '*OneOfEight,parts=4',
                   '*OneOfEight,parts=1',
                   '*OneOfEight,parts=octant',
                   '*OneOfEight,parts=octant_up',
                   '*OneOfEight,parts=3mid',
                   '*OneOfEight,parts=3side',
                   '*OneOfEight,parts=wedge',

                   '*HTree',
                  );
# expand arg "all" to full list
@ARGV = map {$_ eq 'all' ? @all_classes : $_} @ARGV;

my $separator = '';
foreach my $class (@ARGV) {
  print $separator;
  $separator = "\n";

  print_class ($class);
}

sub print_class {
  my ($name) = @_;

  # secret leading "*Foo" means print if available
  my $if_available = ($name =~ s/^\*//);

  my $class = $name;
  unless ($class =~ /::/) {
    $class = "Math::PlanePath::$class";
  }
  ($class, my @parameters) = split /\s*,\s*/, $class;

  $class =~ /^[a-z_][:a-z_0-9]*$/i or die "Bad class name: $class";
  if (! eval "require $class") {
    if ($if_available) {
      next;
    } else {
      die $@;
    }
  }

  @parameters = map { /(.*?)=(.*)/ or die "Missing value for parameter \"$_\"";
                      $1,$2 } @parameters;

  my %rows;
  my $x_min = 0;
  my $x_max = 0;
  my $y_min = 0;
  my $y_max = 0;
  my $cellwidth = 1;

  my $path = $class->new (width  => POSIX::ceil($width / 4),
                          height => POSIX::ceil($height / 2),
                          @parameters);
  my $x_limit_lo;
  my $x_limit_hi;
  if ($path->x_negative) {
    my $w_cells = int ($width / $cellwidth);
    my $half = int(($w_cells - 1) / 2);
    $x_limit_lo = -$half;
    $x_limit_hi = +$half;
  } else {
    my $w_cells = int ($width / $cellwidth);
    $x_limit_lo = 0;
    $x_limit_hi = $w_cells - 1;
  }

  my $y_limit_lo = 0;
  my $y_limit_hi = $height-1;
  if ($path->y_negative) {
    my $half = int(($height-1)/2);
    $y_limit_lo = -$half;
    $y_limit_hi = +$half;
  }

  my $n_start = $path->n_start;
  my $n = $n_start;
  for ($n = $n_start; $n <= 999; $n++) {
    my ($x, $y) = $path->n_to_xy ($n);

    # stretch these out for better resolution
    if ($class =~ /Sacks/) { $x *= 1.5; $y *= 2; }
    if ($class =~ /Archimedean/) { $x *= 2; $y *= 3; }
    if ($class =~ /Theodorus|MultipleRings/) { $x *= 2; $y *= 2; }
    if ($class =~ /Vogel/) { $x *= 2; $y *= 3.5; }

    # nearest integers
    $x = POSIX::floor ($x + 0.5);
    $y = POSIX::floor ($y + 0.5);

    my $cell = $rows{$x}{$y};
    if (defined $cell) { $cell .= ','; }
    $cell .= $n;
    my $new_cellwidth = max ($cellwidth, length($cell) + 1);

    my $new_x_limit_lo;
    my $new_x_limit_hi;
    if ($path->x_negative) {
      my $w_cells = int ($width / $new_cellwidth);
      my $half = int(($w_cells - 1) / 2);
      $new_x_limit_lo = -$half;
      $new_x_limit_hi = +$half;
    } else {
      my $w_cells = int ($width / $new_cellwidth);
      $new_x_limit_lo = 0;
      $new_x_limit_hi = $w_cells - 1;
    }

    my $new_x_min = min($x_min, $x);
    my $new_x_max = max($x_max, $x);
    my $new_y_min = min($y_min, $y);
    my $new_y_max = max($y_max, $y);
    if ($new_x_min < $new_x_limit_lo
        || $new_x_max > $new_x_limit_hi
        || $new_y_min < $y_limit_lo
        || $new_y_max > $y_limit_hi) {
      last;
    }

    $rows{$x}{$y} = $cell;
    $cellwidth = $new_cellwidth;
    $x_limit_lo = $new_x_limit_lo;
    $x_limit_hi = $new_x_limit_hi;
    $x_min = $new_x_min;
    $x_max = $new_x_max;
    $y_min = $new_y_min;
    $y_max = $new_y_max;
  }
  $n--; # the last N actually plotted

  print "$name   N=$n_start to N=$n\n\n";
  foreach my $y (reverse $y_min .. $y_max) {
    foreach my $x ($x_limit_lo .. $x_limit_hi) {
      my $cell = $rows{$x}{$y};
      if (! defined $cell) { $cell = ''; }
      printf ('%*s', $cellwidth, $cell);
    }
    print "\n";
  }
}

exit 0;
