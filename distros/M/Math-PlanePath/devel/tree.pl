#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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

use 5.006;
use strict;
use warnings;
use POSIX qw(floor ceil);
use List::Util qw(min max);
use Module::Load;
use App::MathImage::LinesTree;

# uncomment this to run the ### lines
#use Smart::Comments;

{
  my $path_class;
  require Math::PlanePath::Hypot;
  require Math::PlanePath::HypotOctant;
  require Math::PlanePath::PythagoreanTree;
  require Math::PlanePath::GreekKeySpiral;
  require Math::PlanePath::PixelRings;
  require Math::PlanePath::TriangularHypot;
  require Math::PlanePath::Diagonals;
  require Math::PlanePath::SquareArms;
  require Math::PlanePath::CellularRule54;
  require Math::PlanePath::SquareReplicate;
  require Math::PlanePath::KochSquareflakes;
  require Math::PlanePath::SierpinskiTriangle;
  require Math::PlanePath::DivisibleColumns;
  require Math::PlanePath::DiamondSpiral;
  require Math::PlanePath::DigitGroups;
  require Math::PlanePath::DekkingCurve;
  require Math::PlanePath::DekkingStraight;
  require Math::PlanePath::HilbertCurve;
  require Math::PlanePath::SierpinskiArrowheadCentres;
  require Math::PlanePath::SquareSpiral;
  require Math::PlanePath::PentSpiral;
  require Math::PlanePath::PentSpiralSkewed;
  require Math::PlanePath::HexArms;
  require Math::PlanePath::TriangleSpiral;
  require Math::PlanePath::TriangleSpiralSkewed;
  require Math::PlanePath::KochelCurve;
  require Math::PlanePath::MPeaks;
  require Math::PlanePath::CincoCurve;
  require Math::PlanePath::DiagonalRationals;
  require Math::PlanePath::FactorRationals;
  require Math::PlanePath::VogelFloret;
  require Math::PlanePath::CellularRule;
  require Math::PlanePath::ComplexPlus;
  require Math::PlanePath::AnvilSpiral;
  require Math::PlanePath::CellularRule57;
  require Math::PlanePath::CretanLabyrinth;
  require Math::PlanePath::PeanoHalf;
  require Math::PlanePath::StaircaseAlternating;
  require Math::PlanePath::SierpinskiCurveStair;
  require Math::PlanePath::AztecDiamondRings;
  require Math::PlanePath::PyramidRows;
  require Math::PlanePath::MultipleRings;
  require Math::PlanePath::SacksSpiral;
  require Math::PlanePath::TheodorusSpiral;
  require Math::PlanePath::FilledRings;
  require Math::PlanePath::ImaginaryHalf;
  require Math::PlanePath::MooreSpiral;
  require Math::PlanePath::QuintetSide;
  require Math::PlanePath::PeanoRounded;
  require Math::PlanePath::GosperSide;
  $path_class = 'Math::PlanePath::ComplexMinus';
  $path_class = 'Math::PlanePath::QuadricCurve';
  $path_class = 'Math::PlanePath::QuintetReplicate';
  $path_class = 'Math::PlanePath::SierpinskiCurve';
  $path_class = 'Math::PlanePath::LTiling';
  $path_class = 'Math::PlanePath::ImaginaryHalf';
  $path_class = 'Math::PlanePath::ImaginaryBase';
  $path_class = 'Math::PlanePath::TerdragonCurve';
  $path_class = 'Math::PlanePath::TerdragonMidpoint';
  $path_class = 'Math::PlanePath::TerdragonRounded';
  $path_class = 'Math::PlanePath::DragonCurve';
  $path_class = 'Math::PlanePath::SierpinskiArrowhead';
  $path_class = 'Math::PlanePath::DragonMidpoint';
  $path_class = 'Math::PlanePath::QuintetCentres';
  $path_class = 'Math::PlanePath::QuintetCurve';
  $path_class = 'Math::PlanePath::GosperReplicate';
  $path_class = 'Math::PlanePath::HIndexing';
  $path_class = 'Math::PlanePath::CornerReplicate';
  $path_class = 'Math::PlanePath::WunderlichMeander';
  $path_class = 'Math::PlanePath::ComplexRevolving';
  $path_class = 'Math::PlanePath::AlternatePaper';
  $path_class = 'Math::PlanePath::WunderlichSerpentine';
  $path_class = 'Math::PlanePath::PeanoCurve';
  $path_class = 'Math::PlanePath::Flowsnake';
  $path_class = 'Math::PlanePath::FlowsnakeCentres';
  $path_class = 'Math::PlanePath::FractionsTree';
  $path_class = 'Math::PlanePath::RationalsTree';
  $path_class = 'Math::PlanePath::GrayCode';
  $path_class = 'Math::PlanePath::CubicBase';
  $path_class = 'Math::PlanePath::R5DragonCurve';
  $path_class = 'Math::PlanePath::R5DragonMidpoint';
  $path_class = 'Math::PlanePath::HilbertSpiral';
  $path_class = 'Math::PlanePath::BetaOmega';
  $path_class = 'Math::PlanePath::AR2W2Curve';
  $path_class = 'Math::PlanePath::CCurve';
  $path_class = 'Math::PlanePath::GcdRationals';
  $path_class = 'Math::PlanePath::DiagonalsOctant';
  $path_class = 'Math::PlanePath::KochSnowflakes';
  $path_class = 'Math::PlanePath::GosperIslands';
  $path_class = 'Math::PlanePath::Corner';
  $path_class = 'Math::PlanePath::KochCurve';
  $path_class = 'Math::PlanePath::QuadricIslands';
  $path_class = 'Math::PlanePath::KochPeaks';
  $path_class = 'Math::PlanePath::UlamWarburton';
  $path_class = 'Math::PlanePath::DragonRounded';

  Module::Load::load($path_class);
  my $path = $path_class->new
    (
    );
  ### $path
  my ($prev_x, $prev_y);
  my %seen;
  my $n_start = $path->n_start;
  my $arms_count = $path->arms_count;
  print "n_start $n_start arms_count $arms_count   ",ref($path),"\n";

  for (my $i = $n_start+0; $i <= 32; $i+=1) {
    #for (my $i = $n_start; $i <= $n_start + 800000; $i=POSIX::ceil($i*2.01+1)) {

    my @n_children = $path->MathImage__tree_n_children($i);
    my $n_children = join(', ', @n_children);

    my $iwidth = ($i == int($i) ? 0 : 2);
    printf "%.*f   %s\n",
      $iwidth,$i,
        $n_children;

    foreach my $n_child (@n_children) {
      my $n_parent = $path->MathImage__tree_n_parent($n_child);
      if (! defined $n_parent || $n_parent != $i) {
        $n_parent //= 'undef';
        print "  oops child=$n_child, parent=$n_parent\n";
      }
    }
  }
  exit 0;
}
