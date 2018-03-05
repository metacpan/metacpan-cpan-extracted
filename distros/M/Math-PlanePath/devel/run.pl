#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
use Math::Libm;
use List::Util qw(min max);
use Module::Load;
use Math::PlanePath::Base::Digits 'round_down_pow';

# uncomment this to run the ### lines
# use Smart::Comments;

{
  my $path_class;
  $path_class = 'Math::PlanePath::QuadricCurve';
  $path_class = 'Math::PlanePath::LTiling';
  $path_class = 'Math::PlanePath::TerdragonMidpoint';
  $path_class = 'Math::PlanePath::SierpinskiArrowhead';
  $path_class = 'Math::PlanePath::QuintetCentres';
  $path_class = 'Math::PlanePath::HIndexing';
  $path_class = 'Math::PlanePath::WunderlichSerpentine';
  $path_class = 'Math::PlanePath::R5DragonMidpoint';
  $path_class = 'Math::PlanePath::NxN';
  $path_class = 'Math::PlanePath::NxNinv';
  $path_class = 'Math::PlanePath::Dispersion';
  $path_class = 'Math::PlanePath::KochSquareflakes';
  $path_class = 'Math::PlanePath::HilbertSpiral';
  $path_class = 'Math::PlanePath::GreekKeySpiral';
  $path_class = 'Math::PlanePath::ComplexMinus';
  $path_class = 'Math::PlanePath::GosperReplicate';
  $path_class = 'Math::PlanePath::ComplexPlus';
  $path_class = 'Math::PlanePath::CubicBase';
  $path_class = 'Math::PlanePath::DigitGroups';
  $path_class = 'Math::PlanePath::GrayCode';
  $path_class = 'Math::PlanePath::ZOrderCurve';
  $path_class = 'Math::PlanePath::ImaginaryBase';
  $path_class = 'Math::PlanePath::KochCurve';
  $path_class = 'Math::PlanePath::PixelRings';
  $path_class = 'Math::PlanePath::TriangleSpiral';
  $path_class = 'Math::PlanePath::HypotOctant';
  $path_class = 'Math::PlanePath::SquareSpiral';
  $path_class = 'Math::PlanePath::PowerArray';
  $path_class = 'Math::PlanePath::ParabolicRuns';
  $path_class = 'Math::PlanePath::DiagonalsOctant';
  $path_class = 'Math::PlanePath::PyramidRows';
  $path_class = 'Math::PlanePath::Corner';
  $path_class = 'Math::PlanePath::ComplexRevolving';
  $path_class = 'Math::PlanePath::DragonMidpoint';
  $path_class = 'Math::PlanePath::ParabolicRows';
  $path_class = 'Math::PlanePath::TriangularHypot';
  $path_class = 'Math::PlanePath::SierpinskiArrowheadCentres';
  $path_class = 'Math::PlanePath::DiamondSpiral';
  $path_class = 'Math::PlanePath::DragonCurve';
  $path_class = 'Math::PlanePath::KochelCurve';
  $path_class = 'Math::PlanePath::FibonacciWordFractal';
  $path_class = 'Math::PlanePath::CincoCurve';
  $path_class = 'Math::PlanePath::WunderlichMeander';
  $path_class = 'Math::PlanePath::AR2W2Curve';
  $path_class = 'Math::PlanePath::AlternatePaperMidpoint';
  $path_class = 'Math::PlanePath::BetaOmega';
  $path_class = 'Math::PlanePath::FractionsTree';
  $path_class = 'Math::PlanePath::R5DragonCurve';
  $path_class = 'Math::PlanePath::GcdRationals';
  $path_class = 'Math::PlanePath::Diagonals';
  $path_class = 'Math::PlanePath::LToothpickTree';
  $path_class = 'Math::PlanePath::CfracDigits';
  $path_class = 'Math::PlanePath::BalancedArray';
  $path_class = 'Math::PlanePath::FibonacciWordKnott';
  $path_class = 'Math::PlanePath::LCornerReplicate';
  $path_class = 'Math::PlanePath::HilbertCurve';
  $path_class = 'Math::PlanePath::ImaginaryHalf';
  $path_class = 'Math::PlanePath::R7DragonCurve';
  $path_class = 'Math::PlanePath::GosperIslands';
  $path_class = 'Math::PlanePath::ToothpickReplicate';
  $path_class = 'Math::PlanePath::EToothpickTree';
  $path_class = 'Math::PlanePath::Hypot';
  $path_class = 'Math::PlanePath::SierpinskiCurve';
  $path_class = 'Math::PlanePath::FlowsnakeCentres';
  $path_class = 'Math::PlanePath::Flowsnake';
  $path_class = 'Math::PlanePath::LToothpickTree';
  $path_class = 'Math::PlanePath::AnvilSpiral';
  $path_class = 'Math::PlanePath::FilledRings';
  $path_class = 'Math::PlanePath::HexSpiral';
  $path_class = 'Math::PlanePath::HexSpiralSkewed';
  $path_class = 'Math::PlanePath::TwoOfEightByCells';
  $path_class = 'Math::PlanePath::DivisibleColumns';
  $path_class = 'Math::PlanePath::PeninsulaBridge';
  $path_class = 'Math::PlanePath::PowerRows';
  $path_class = 'Math::PlanePath::WythoffDifference';
  $path_class = 'Math::PlanePath::WythoffTriangle';
  $path_class = 'Math::PlanePath::WythoffArray';
  $path_class = 'Math::PlanePath::SumFractions';
  $path_class = 'Math::PlanePath::AztecDiamondRings';
  $path_class = 'Math::PlanePath::TriangleSpiralSkewed';
  $path_class = 'Math::PlanePath::PeanoCurve';
  $path_class = 'Math::PlanePath::CellularRule190';
  $path_class = 'Math::PlanePath::CellularRule54';
  $path_class = 'Math::PlanePath::PeanoVertices';
  $path_class = 'Math::PlanePath::OneOfEightByCells';
  $path_class = 'Math::PlanePath::ZeckendorfTerms';
  $path_class = 'Math::PlanePath::BinaryTerms';
  $path_class = 'Math::PlanePath::LCornerTreeByCells';
  $path_class = 'Math::PlanePath::UlamWarburtonOld';
  $path_class = 'Math::PlanePath::LCornerTree';
  $path_class = 'Math::PlanePath::ToothpickSpiral';
  $path_class = 'Math::PlanePath::ChanTree';
  $path_class = 'Math::PlanePath::RationalsTree';
  $path_class = 'Math::PlanePath::PyramidSpiral';
  $path_class = 'Math::PlanePath::CornerReplicate';
  $path_class = 'Math::PlanePath::WythoffPreliminaryTriangle';
  $path_class = 'Math::PlanePath::WythoffLines';
  $path_class = 'Math::PlanePath::OctagramSpiral';
  $path_class = 'Math::PlanePath::MPeaks';
  $path_class = 'Math::PlanePath::KnightSpiral';
  $path_class = 'Math::PlanePath::PentSpiralSkewed';
  $path_class = 'Math::PlanePath::PentSpiral';
  $path_class = 'Math::PlanePath::HeptSpiralSkewed';
  $path_class = 'Math::PlanePath::FourReplicate';
  $path_class = 'Math::PlanePath::DiagonalsAlternating';
  $path_class = 'Math::PlanePath::ToothpickTreeByCells';
  $path_class = 'Math::PlanePath::FactorRationals';
  $path_class = 'Math::PlanePath::MultipleRings';
  $path_class = 'Math::PlanePath::HTreeByCells';
  $path_class = 'Math::PlanePath::ToothpickUpist';
  $path_class = 'Math::PlanePath::HTree';
  $path_class = 'Math::PlanePath::CCurve';
  $path_class = 'Math::PlanePath::Z2DragonCurve';
  $path_class = 'Math::PlanePath::Godfrey';
  $path_class = 'Math::PlanePath::CellularRule';
  $path_class = 'Math::PlanePath::CoprimeColumns';
  $path_class = 'Math::PlanePath::DiagonalRationals';
  $path_class = 'Math::PlanePath::OneOfEight';
  $path_class = 'Math::PlanePath::PythagoreanTree';
  $path_class = 'Math::PlanePath::UlamWarburtonQuarter';
  $path_class = 'Math::PlanePath::UlamWarburton';
  $path_class = 'Math::PlanePath::ToothpickTree';
  $path_class = 'Math::PlanePath::DekkingCentres';
  $path_class = 'Math::PlanePath::DekkingCurve';
  $path_class = 'Math::PlanePath::SierpinskiTriangle';
  $path_class = 'Math::PlanePath::AlternatePaper';
  $path_class = 'Math::PlanePath::HilbertSides';
  $path_class = 'Math::PlanePath::SquaRecurve';
  $path_class = 'Math::PlanePath::QuintetCurve';
  $path_class = 'Math::PlanePath::SquareReplicate';
  $path_class = 'Math::PlanePath::QuintetReplicate';
  $path_class = 'Math::PlanePath::AlternateTerdragon';
  $path_class = 'Math::PlanePath::TerdragonRounded';
  $path_class = 'Math::PlanePath::TerdragonCurve';

  my $lo = 0;
  my $hi = 40;

  Module::Load::load($path_class);
  my $path = $path_class->new
    (
     arms => 2,

     # numbering_type => 'rotate',
     # k=>5,
     # align => 'right',
     # parts => 'left',

     # direction => 'up',
     # coordinates => 'ST',
     # tree_type => 'UAD',

     #  ring_shape => 'polygon',
     # step => 1,

     # sign_encoding => 'revbinary',

     # n_start => 0,
     # parts => 'wedge',
     # shift => 6,
     # pn_encoding => 'negabinary',
     #  points => 'all_mul',
     # k => 4,
     # digit_order => 'HtoL',
     # digit_order => 'LtoH',
     # reduced => 1,
     # radix => 4,

     # rule => 14,
     # x_start => 5,
     # y_start => 2,

     # divisor_type => 'proper',

     # wider => 3,
     # reverse => 1,
     # tree_type => 'L',
     # sides=>3,
     # digit_order => 'XnYX',
     # radix => 2,
     # points => 'square_centred',
     # pairs_order => 'rows_reverse',
     # pairs_order => 'diagonals_up',
     # tree_type => 'HCS',
     # start => 'snowflake',
     # n_start=>37,
     # step => 5,
     # n_start => 37,
     # align => 'diagonal',
     # offset => -0.5,
     # turns => 1,
     # base => 7,
     # diagonal_length => 5,
     # apply_type => 'FS',
     # serpentine_type => '010_000',
     # straight_spacing => 3,
     # diagonal_spacing => 7,
     # arms => 7,
     # wider => 3,
     # realpart => 1,
     # mirror => 1,
    );
  ### $path
  my %seen;
  my $n_start = $path->n_start;
  my $arms_count = $path->arms_count;
  my $path_ref = ref($path);
  print "n_start()=$n_start arms_count()=$arms_count   $path_ref\n";

  {
    my $num_roots = $path->tree_num_roots();
    my @n_list = $path->tree_root_n_list();
    print "  $num_roots roots n=",join(',',@n_list),"\n";
  }

  {
    require Data::Float;
    my $pos_infinity = Data::Float::pos_infinity();
    my $neg_infinity = Data::Float::neg_infinity();
    my $nan = Data::Float::nan();
    $path->n_to_xy($pos_infinity);
    $path->n_to_xy($neg_infinity);
    $path->n_to_xy($nan);
    $path->xy_to_n(0,$pos_infinity);
    $path->xy_to_n(0,$neg_infinity);
    $path->xy_to_n(0,$nan);
    $path->xy_to_n($pos_infinity,0);
    $path->xy_to_n($neg_infinity,0);
    $path->xy_to_n($nan,0);
    $path->rect_to_n_range($pos_infinity,0,0,0);
    $path->rect_to_n_range($neg_infinity,0,0,0);
    $path->rect_to_n_range($nan,0,0,0);
    $path->rect_to_n_range(0,$pos_infinity,0,0);
    $path->rect_to_n_range(0,$neg_infinity,0,0);
    $path->rect_to_n_range(0,$nan,0,0);
  }

  for (my $i = $n_start+$lo; $i <= $hi; $i+=1) {
    #for (my $i = $n_start; $i <= $n_start + 800000; $i=POSIX::ceil($i*2.01+1)) {

    my ($x, $y) = $path->n_to_xy($i) or next;
    # next unless $x < 0; # abs($x)>abs($y) && $x > 0;

    my $dxdy = '';
    my $diffdxdy = '';
    my ($dx, $dy) = $path->n_to_dxdy($i);
    if (defined $dx && defined $dy) {
      my $d = Math::Libm::hypot($dx,$dy);
      $dxdy = sprintf "%.3f,%.3f(%.3f)", $dx,$dy,$d;
    } else {
      $dxdy='[undef]';
    }

    my ($next_x, $next_y) = $path->n_to_xy($i+$arms_count);
    if (defined $next_x && defined $next_y) {
      my $want_dx = $next_x - $x;
      my $want_dy = $next_y - $y;
      if ($dx != $want_dx || $dy != $want_dy) {
        $diffdxdy = "dxdy(want $want_dx,$want_dy)";
      }
    }

    my $rep = '';
    my $xy = (defined $x ? $x : 'undef').','.(defined $y ? $y : 'undef');
    if (defined $seen{$xy}) {
      $rep = "rep$seen{$xy}";
      $seen{$xy} .= ",$i";
    } else {
      $seen{$xy} = $i;
    }

    my @n_list = $path->xy_to_n_list ($x+.0, $y-.0);
    my $n_rev;
    if (@n_list) {
      $n_rev = join(',',@n_list);
    } else {
      $n_rev = 'norev';
    }
    my $rev = '';
    if (@n_list && $n_list[0] ne $seen{$xy}) {
      $rev = 'Rev';
    }

    my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
    my $range = '';
    if ($n_hi < $i || $n_lo > $i) {
      $range = 'Range';
    }

    my $n_children = '';
    my @n_children = $path->tree_n_children ($i);
    if (@n_children) {
      $n_children = " c=";
      foreach my $n_child (@n_children) {
        my $n_parent = $path->tree_n_parent($n_child);
        if (! defined $n_parent || $n_parent != $i) {
          $n_children .= "***";
        }
        $n_children .= $n_child;
        $n_children .= ",";
      }
      $n_children =~ s/,$//;
    }
    my $num_children = $path->tree_n_num_children($i);
    if (! defined $num_children || $num_children != scalar(@n_children)) {
      $n_children .= "numchildren***";
    }

    my $depth = $path->tree_n_to_depth($i);
    if (defined $depth) {
      $n_children .= " d=$depth";
    }

    my $baddepth = '';
    if ($path->can('tree_n_to_depth')
        != Math::PlanePath->can('tree_n_to_depth')) {
      my $depth = $path->tree_n_to_depth($i);
      my $calc_depth = path_tree_n_to_depth_by_parents($path,$i);
      if (! defined $depth || $calc_depth != $depth) {
        $baddepth .= "ntodepth=$depth,parentcalc=$calc_depth";
      }
    }

    my $flag = '';
    if ($rev || $range || $diffdxdy || $baddepth) {
      $flag .= "  ***$rev$range$diffdxdy$baddepth";
    }

    if (! defined $n_lo) { $n_lo = 'undef'; }
    if (! defined $n_hi) { $n_hi = 'undef'; }

    my $iwidth = ($i == int($i) ? 0 : 2);
    printf "%.*f %7.3f,%7.3f   %3s  %s  %s%s %s %s\n",
      $iwidth,$i,  $x,$y,
      $n_rev,
      "${n_lo}_${n_hi}",
      $dxdy,
      $n_children,
      " $rep",
      $flag;

    # %.2f ($x*$x+$y*$y),
  }
  exit 0;
}

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
      warn "Oops, tree parent $parent_n >= child $n in ", ref $path;
      return -1;
    }
    $n = $parent_n;
    $depth++;
  }
  return $depth;
}


__END__
{
  use Math::PlanePath::KochCurve;
  package Math::PlanePath::KochCurve;
  sub rect_to_n_range {
    my ($self, $x1,$y1, $x2,$y2) = @_;

    $y1 = round_nearest ($y1);
    $y2 = round_nearest ($y2);
    if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1) }
    if ($y2 < 0) {
      return (1,0);
    }

    $x1 = round_nearest ($x1);
    $x2 = round_nearest ($x2);
    if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1) }
    ### rect_to_n_range(): "$x1,$y1  $x2,$y2"

    my (undef, $top_level) = round_down_pow (max(2, abs($x1), abs($x2)),
                                             3);
    $top_level += 2;
    ### $top_level

    my ($tx,$ty, $dir, $len);
    my $intersect_rect_p = sub {
      if ($dir < 0) {
        $dir += 6;
      } elsif ($dir > 5) {
        $dir -= 6;
      }
      my $left_x = $tx;
      my $peak_y = $ty;
      my $offset;
      if ($dir & 1) {
        # pointing downwards
        if ($dir == 1) {
          $left_x -= $len-1;  # +1 to exclude left edge
          $peak_y += $len;
        } elsif ($dir == 3) {
          $left_x -= 2*$len;
        } else {
          $peak_y++;  # exclude top edge
        }
        if ($peak_y < $y1) {
          ### all below ...
          return 0;
        }
        $offset = $y2 - $peak_y;

      } else {
        # pointing upwards
        if ($dir == 2) {
          $left_x -= 2*$len;
        } elsif ($dir == 4) {
          $left_x -= $len;
          $peak_y -= $len-1;  # +1 exclude bottom edge
        }
        if ($peak_y > $y2) {
          ### all above ...
          return 0;
        }
        $offset = $peak_y - $y1;
      }
      my $right_x = $left_x + 2*($len-1);
      if ($offset > 0) {
        $left_x += $offset;
        $right_x -= $offset;
      }
      ### $offset
      ### $left_x
      ### $right_x
      ### result: ($left_x <= $x2 && $right_x >= $x1)
      return ($left_x <= $x2 && $right_x >= $x1);
    };

    my @pending_tx = (0);
    my @pending_ty = (0);
    my @pending_dir = (0);
    my @pending_level = ($top_level);
    my @pending_n = (0);

    my $n_lo;
    for (;;) {
      if (! @pending_tx) {
        ### nothing in rectangle for low ...
        return (1,0);
      }
      $tx = pop @pending_tx;
      $ty = pop @pending_ty;
      $dir = pop @pending_dir;
      my $level = pop @pending_level;
      my $n = pop @pending_n;
      $len = 3**$level;

      ### pop for low ...
      ### n: sprintf('0x%X',$n)
      ### $level
      ### $len
      ### $tx
      ### $ty
      ### $dir

      unless (&$intersect_rect_p()) {
        next;
      }
      $level--;
      if ($level < 0) {
        $n_lo = $n;
        last;
      }
      $n *= 4;
      $len = 3**$level;

      ### descend: "len=$len"
      push @pending_tx, $tx+4*$len;
      push @pending_ty, $ty;
      push @pending_dir, $dir;
      push @pending_level, $level;
      push @pending_n, $n+3;

      push @pending_tx, $tx+3*$len;
      push @pending_ty, $ty;
      push @pending_dir, $dir-1;
      push @pending_level, $level;
      push @pending_n, $n+2;

      push @pending_tx, $tx+2*$len;
      push @pending_ty, $ty;
      push @pending_dir, $dir+1;
      push @pending_level, $level;
      push @pending_n, $n+1;

      push @pending_tx, $tx;
      push @pending_ty, $ty;
      push @pending_dir, $dir;
      push @pending_level, $level;
      push @pending_n, $n;
    }

    ### high ...

    @pending_tx = (0);
    @pending_ty = (0);
    @pending_dir = (0);
    @pending_level = ($top_level);
    @pending_n = (0);

    for (;;) {
      if (! @pending_tx) {
        ### nothing in rectangle for high ...
        return (1,0);
      }
      $tx = pop @pending_tx;
      $ty = pop @pending_ty;
      $dir = pop @pending_dir;
      my $level = pop @pending_level;
      my $n = pop @pending_n;

      ### pop for high ...
      ### n: sprintf('0x%X',$n)
      ### $level
      ### $len
      ### $tx
      ### $ty
      ### $dir

      $len = 3**$level;
      unless (&$intersect_rect_p()) {
        next;
      }
      $level--;
      if ($level < 0) {
        return ($n_lo, $n);
      }
      $n *= 4;
      $len = 3**$level;

      ### descend
      push @pending_tx, $tx;
      push @pending_ty, $ty;
      push @pending_dir, $dir;
      push @pending_level, $level;
      push @pending_n, $n;

      push @pending_tx, $tx+2*$len;
      push @pending_ty, $ty;
      push @pending_dir, $dir+1;
      push @pending_level, $level;
      push @pending_n, $n+1;

      push @pending_tx, $tx+3*$len;
      push @pending_ty, $ty;
      push @pending_dir, $dir-1;
      push @pending_level, $level;
      push @pending_n, $n+2;

      push @pending_tx, $tx+4*$len;
      push @pending_ty, $ty;
      push @pending_dir, $dir;
      push @pending_level, $level;
      push @pending_n, $n+3;
    }
  }
}
{
  require Math::PlanePath::KochSnowflakes;
  my $path = Math::PlanePath::KochSnowflakes->new;
  my @range = $path->rect_to_n_range (0,0, 0,2);
  ### @range
  exit 0;
}
{
  require Math::PlanePath::PixelRings;
  my $path = Math::PlanePath::PixelRings->new
    (wider => 0,
     # step => 0,
     #tree_type => 'UAD',
     #coordinates => 'PQ',
    );
  ### xy: $path->n_to_xy(500)
  ### n: $path->xy_to_n(3,3)
  exit 0;
}




# cf turn_any_left()

=over

=item C<$lsr = $path-E<gt>n_to_turn_LSR ($n)>

Return the turn at C<$n> in the form

      1     left turn
      0     straight or 180 reverse or no move at all
     -1     right turn
    undef   no turn exists at $n

The path is taken to go in a line from C<$n-1> to C<$n> and the turn is then
whether C<$n+1> is left, right, or on that line.  C<$n> can be fractional.
If there is no X,Y for any of the three points considered then the return is
C<undef>.

=item C<$lsr = $path-E<gt>turn_LSR_minimum>

=item C<$lsr = $path-E<gt>turn_LSR_maximum>

Return the minimum or maximum LSR value returned by
C<$path-E<gt>n_to_turn_LSR($n)> for integer N values in the path.  If there
are no turns at all then return C<undef>.

=back
