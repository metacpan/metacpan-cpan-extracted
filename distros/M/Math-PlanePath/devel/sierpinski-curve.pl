#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015 Kevin Ryde

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
use POSIX ();
use Math::Trig 'pi';
use Math::PlanePath::SierpinskiCurve;

# uncomment this to run the ### lines
# use Smart::Comments;

# Nlevel A146882 5*(4^(n+1)-1)/3 = 5*A002450


# =for Test-Pari-DEFINE  Ytop(k,L) = if(k==0,0, (L+2)*2^(k-1) - 2)
# 
# =for GP-Test  Ytop(0,1) == 0
# 
# =for GP-Test  Ytop(1,1) == 1
# 
# =for GP-Test  Ytop(2,1) == 4
# 
# =for GP-Test  Ytop(3,1) == 10
# 
#     Ytop[k] = /  0                   if k = 0
#               \  (L+2)*2^(k-1) - 2   if k > 0
#             = 0, 1, 4, 10, 22, 46, 94, 190, ...
#               for L=1
# 
# This is the same as C<SierpinskiCurve> but
# 
#     Nlevel = ((3L+2)*4^level - 5) / 3
#     Nlevel = 4^level - 1 + ((3L+2)*4^level - 5) / 3 - 4^level + 1
#     Nlevel = 4^level - 1 + ((3L+2)*4^level - 5 - 3*4^level + 3) / 3
#     Nlevel = 4^level - 1 + ((3L-1)*4^level - 2) / 3
# 
# 
# 
# For C<diagonal_length> = L and reckoning the first diagonal side N=0 to N=2L
# as level 0, a level extends out to a triangle
# 
#     Nlevel = ((6L+4)*4^level - 4) / 3
#     Xlevel = (L+2)*2^level - 1
# 
# For example level 2 in the default L=1 goes to N=((6*1+4)*4^2-4)/3=52 and
# Xlevel=(1+2)*2^2-1=11.  Or in the L=4 sample above level 1 is
# N=((6*4+4)*4^1-4)/3=36 and Xlevel=(4+2)*2^1-1=11.
# 
# The power-of-4 in Nlevel is per the plain C<SierpinskiCurve>, with factor
# 2L+1 for the points making the diagonal stair.  The "/3" arises from the
# extra points between replications.  They become a power-of-4 series
# 
#     Nextras = 1+4+4^2+...+4^(level-1) = (4^level-1)/3
# 
# For example level 1 is Nextras=(4^1-1)/3=1, being point N=6 in the default
# L=1.  Or for level 2 Nextras=(4^2-1)/3=5 at N=6 and N=19,26,33,46.

{
  # between two curves
  #   (13*4^k - 7)/3
  #   = 2 15 67 275 1107 4435 17747 70995 283987 1135955
  #   not in OEIS
  # area=2 initial diamond is level=0

  require Math::Geometry::Planar;
  my $path = Math::PlanePath::SierpinskiCurve->new (arms => 2);
  my @values;

  foreach my $level (0 .. 8) {
    my $n_hi = 4**($level+1) - 1;
    my @points;
    for (my $n = 0; $n <= $n_hi; $n+=2) {
      my ($x,$y) = $path->n_to_xy($n);
      push @points, [$x,$y];
    }
    for (my $n = $n_hi; $n >= 0; $n-=2) {
      my ($x,$y) = $path->n_to_xy($n);
      push @points, [$x,$y];
    }
    ### @points
    my $polygon = Math::Geometry::Planar->new;
    $polygon->points(\@points);
    my $area = $polygon->area;
    my $length = $polygon->perimeter;

    my $formula = two_area_by_formula($level);

    print "$level  $length  area $area $formula\n";
    push @values, $area;
  }
  shift @values;
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;

  sub two_area_by_formula {
    my ($k) = @_;

    return (13*4**$k - 7) / 3;

    $k++;
    return (27*4**($k-1) - 18*2**($k-1) -14 * 4**($k-1) + 18 * 2**($k-1) - 4) / 3 - 1;
    return 9*4**($k-1) - 6*2**($k-1) + (-14 * 4**($k-1) + 18 * 2**($k-1) - 4) / 3 - 1;
    return 9*4**($k-1) - 6*2**($k-1) - (14 * 4**($k-1) - 18 * 2**($k-1) + 4) / 3 - 1;
    return 9*2**(2*$k-2) - 2*3*2**($k-1) + 1 - (14 * 4**($k-1) - 18 * 2**($k-1) + 4) / 3 - 2;
    return (3*2**($k-1) - 1)**2 - (14 * 4**($k-1) - 18 * 2**($k-1) + 4) / 3 - 2;
    return (3*2**($k-1) - 1)**2 - 4*(7 * 4**($k-1) - 9 * 2**($k-1) + 2) / 6 - 2;
    return (3*2**($k-1) - 2 + 1)**2 - 4*((7 * 4**($k-1) - 9 * 2**($k-1) + 2) / 6) - 2;
    return (3*2**($k-1) - 2 + 1)**2 - 4*area_by_formula($k-1) - 2;
  }
}

{
  # area under the curve
  #   (7*4^k - 9*2^k + 2)/6
  #
  require Math::Geometry::Planar;
  my $path = Math::PlanePath::SierpinskiCurve->new;
  my @values;

  foreach my $level (1 .. 10) {
    my ($n_lo, $n_hi) = $path->level_to_n_range($level);
    my @points;
    foreach my $n ($n_lo .. $n_hi) {
      my ($x,$y) = $path->n_to_xy($n);
      push @points, [$x,$y];
    }
    my $polygon = Math::Geometry::Planar->new;
    $polygon->points(\@points);
    my $area = $polygon->area;
    my $length = $polygon->perimeter;

    my $formula = area_by_formula($level);

    print "$level  $length  area $area $formula\n";
    push @values, $area;
  }
  shift @values;
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;

  sub area_by_formula {
    my ($k) = @_;
    if ($k == 0) { return 0; }

    return (7 * 4**$k - 9 * 2**$k + 2) / 6;
    return (28 * 4**($k-1) - 18 * 2**($k-1) + 2) / 6;

    {
      return (
              4**($k-1) * 6
              - 4**($k-1) + 1
              + 9*4**($k-1) - 9*2**($k-1)
             )/3;
    }
    {
      return (
              (4**($k-1) * 6 - 4**($k-1) + 1)/3
              + 3*4**($k-1) - 3*2**($k-1));
    }
    {
      return (4**($k-1) * 2
              - (4**($k-1) - 1)/3
              + 3*2* (4**($k-1) - 2**($k-1))/(4-2));
    }

    {
      #                            i=k-2
      #      = 2*4^(k-1) + 3*2 * sum   4^i * 2^(k-2-i)    - (4^(k-1) - 1)/3
      #                            i=0
      #      = 2*4^(k-1) + 3*2 * (4^(k-1) - 2^(k-1))/(4-2)    - (4^(k-2) - 1)/3

      if ($k == 1) { return 2; }
      my $total = 4**($k-1) * 2;
      $total -= (4**($k-1) - 1)/3;
      $total += 3*2* (4**($k-1) - 2**($k-1))/(4-2);
      return $total;
    }
    {
      #                            i=k-2
      #      = 2*4^(k-1) + 3*2^2 * sum   4^i * 2^(k-3-i)    - (4^(k-1) - 1)/3
      #                            i=0
      #      = 2*4^(k-1) + 3*2^2 * (4^(k-1) - 2^(k-1))/(4-2)    - (4^(k-2) - 1)/3

      if ($k == 1) { return 2; }
      my $total = 4**($k-1) * 2;
      $total -= (4**($k-1) - 1)/3;
      foreach my $i (0 .. $k-2) {
        $total += 4**$i * (3 * 2**($k-1-$i));
      }
      return $total;
    }

    {
      # A(2) = 4*A(1) + (3*2^(1) - 1)
      #      =       (3*2^(k-1) - 1)                    0 + k-1 = k-1
      #        + 4  *(3*2^(k-2) - 1)                    1 + k-2 = k-1
      #        + 4^2*(3*2^(k-3) - 1)                    2 + k-2 = k-1
      #        + ...
      #        + 4^(k-3)*(3*2^(2) - 1)      Ytop(2)     k-3 + 2 = k-1
      #        + 4^(k-2)*A(1)
      #                    i=k-2
      #      = 2*4^(k-1) + sum   4^i * (3*2^(k-1-i) - 1)
      #                    i=0
      if ($k == 1) { return 2; }
      my $total = 4**($k-1) * 2;
      foreach my $i (0 .. $k-2) {
        $total += 4**$i * (3 * 2**($k-1-$i) - 1);
      }
      return $total;
    }

    {
      # A(k) = 4*A(k-1) + Ytop(k) + 1      k >= 2
      # A(1) = 2
      # A(0) = 0
      # Ytop(k) = 3*2^(k-1) - 2
      # A(k) = 4*A(k-1) + 3*2^(k-1) - 1
      #
      if ($k == 1) { return 2; }
      return 4*area_by_formula($k-1) + 3 * 2**($k-1) - 1;
    }

  }
}


{
  # Y coordinate sequence
  require Math::NumSeq::PlanePathCoord;
  my $seq = Math::NumSeq::PlanePathCoord->new (planepath => 'SierpinskiCurve',
                                               coordinate_type => 'Sum');
  my @values;
  for (1 .. 500) {
    my ($i,$value) = $seq->next;
    push @values, $value-1;
  }
  unduplicate(\@values);
  print "values: ", join(',', @values), "\n";
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose => 1);
  exit 0;

  sub unduplicate {
    my ($aref) = @_;
    my $i = 1;
    while ($i < $#$aref) {
      if ($aref->[$i] == $aref->[$i-1]) {
        splice @$aref, $i, 1;
      } else {
        $i++;
      }
    }
  }
}
{
  # dSumAbs
  require Math::NumSeq::PlanePathDelta;
  my $seq = Math::NumSeq::PlanePathDelta->new (planepath => 'SierpinskiCurveStair,arms=6',
                                               delta_type => 'dSumAbs');
  for (1 .. 300) {
    my ($i,$value) = $seq->next;
    print "$value,";
    if ($i % 6 == 5) {
      print "\n";
    }
  }
  exit 0;
}
{
  # A156595 Mephisto Waltz first diffs xor as turns
  require Tk;
  require Tk::CanvasLogo;
  require Math::NumSeq::MephistoWaltz;
  my $top = MainWindow->new;
  my $width = 1200;
  my $height = 800;
  my $logo = $top->CanvasLogo(-width => $width, -height => $height)->pack;
  my $turtle = $logo->NewTurtle('foo');
  $turtle->LOGO_PU();
  $turtle->LOGO_FD(- $height/2*.9);
  $turtle->LOGO_PD();

  my $step = 5;
  $turtle->LOGO_FD($step);
  my $seq = Math::NumSeq::MephistoWaltz->new;
  my ($i,$prev) = $seq->next;
  for (;;) {
    my ($i,$value) = $seq->next;
    my $turn = $value ^ $prev;
    $prev = $value;
    last if $i > 10000;
    if ($turn) {
      $turtle->LOGO_FD($step);
      if ($i & 1) {
        $turtle->LOGO_RT(120);
      } else {
        $turtle->LOGO_LT(120);
      }
    } else {
      $turtle->LOGO_FD($step);
    }
    $logo->createArc($turtle->{x}+2, $turtle->{y}+2,
                       $turtle->{x}-2, $turtle->{y}-2);
  }

  Tk::MainLoop();
  exit;
}

{
  # dX,dY
  require Math::PlanePath::SierpinskiCurve;
  my $path = Math::PlanePath::SierpinskiCurve->new;
  foreach my $n (0 .. 32) {
#    my $n = $n + 1/256;
    my ($x,$y) = $path->n_to_xy($n);
    my ($x2,$y2) = $path->n_to_xy($n+1);
    my $sx = $x2-$x;
    my $sy = $y2-$y;
    my $sdir = dxdy_to_dir8($sx,$sy);
    my ($dx,$dy) = $path->_WORKING_BUT_HAIRY__n_to_dxdy($n);
    my $ddir = dxdy_to_dir8($dx,$dy);
    my $diff = ($dx != $sx || $dy != $sy ? '  ***' : '');
    print "$n $x,$y  $sx,$sy\[$sdir]  $dx,$dy\[$ddir]$diff\n";
  }

  # return 0..7
  sub dxdy_to_dir8 {
    my ($dx, $dy) = @_;
    return atan2($dy,$dx) / atan2(1,1);
    if ($dx == 1) {
      if ($dy == 1) { return 1; }
      if ($dy == 0) { return 0; }
      if ($dy == -1) { return 7; }
    }
    if ($dx == 0) {
      if ($dy == 1) { return 2; }
      if ($dy == -1) { return 6; }
    }
    if ($dx == -1) {
      if ($dy == 1) { return 3; }
      if ($dy == 0) { return 4; }
      if ($dy == -1) { return 5; }
    }
    die 'oops';
  }
  exit 0;
}


{
  # Mephisto Waltz 1/12 slice of plane
  require Tk;
  require Tk::CanvasLogo;
  require Math::NumSeq::MephistoWaltz;
  my $top = MainWindow->new;
  my $width = 1000;
  my $height = 800;
  my $logo = $top->CanvasLogo(-width => $width, -height => $height)->pack;
  my $turtle = $logo->NewTurtle('foo');
  $turtle->LOGO_RT(45);
  $turtle->LOGO_PU();
  $turtle->LOGO_FD(- $height*sqrt(2)/2*.9);
  $turtle->LOGO_PD();
  $turtle->LOGO_RT(135);
  $turtle->LOGO_LT(30);

  my $step = 5;
  $turtle->LOGO_FD($step);
  my $seq = Math::NumSeq::MephistoWaltz->new;
  for (;;) {
    my ($i,$value) = $seq->next;
    last if $i > 10000;
    if ($value) {
      $turtle->LOGO_RT(60);
      $turtle->LOGO_FD($step);
    } else {
      $turtle->LOGO_LT(60);
      $turtle->LOGO_FD($step);
    }
  }

  Tk::MainLoop();
  exit;
}

{
  require Tk;
  require Tk::CanvasLogo;
  require Math::NumSeq::PlanePathTurn;
  my $top = MainWindow->new();
  my $logo = $top->CanvasLogo->pack;
  my $turtle = $logo->NewTurtle('foo');

  my $seq = Math::NumSeq::PlanePathTurn->new
    (planepath => 'KochCurve',
     turn_type => 'Left');
  $turtle->LOGO_RT(45);
  $turtle->LOGO_FD(10);
  for (;;) {
    my ($i,$value) = $seq->next;
    last if $i > 64;
    if ($value) {
      $turtle->LOGO_RT(45);
      $turtle->LOGO_FD(10);
      $turtle->LOGO_RT(45);
      $turtle->LOGO_FD(10);
    } else {
      $turtle->LOGO_LT(90);
      $turtle->LOGO_FD(10);
      $turtle->LOGO_LT(90);
      $turtle->LOGO_FD(10);
    }
  }

  Tk::MainLoop();
  exit;
}
{
  # filled fraction

  require Math::PlanePath::SierpinskiCurve;
  require Number::Fraction;
  my $path = Math::PlanePath::SierpinskiCurve->new;
  foreach my $level (1 .. 20) {
    my $Ntop = 4**$level / 2 - 1;
    my ($x,$y) = $path->n_to_xy($Ntop);
    my $Xtop = 3*2**($level-1) - 1;
    $x == $Xtop or die "x=$x Xtop=$Xtop";
    my $frac = $Ntop / ($x*($x-1)/2);
    print "  $level  $frac\n";
  }
  my $nf = Number::Fraction->new(4,9);
  my $limit = $nf->to_num;
  print "  limit  $nf = $limit\n";
  exit 0;
}

{
  # filled fraction

  require Math::PlanePath::SierpinskiCurveStair;
  require Number::Fraction;
  foreach my $L (1 .. 5) {
    print "L=$L\n";
    my $path = Math::PlanePath::SierpinskiCurveStair->new (diagonal_length=>$L);
    foreach my $level (1 .. 10) {
      my $Nlevel = ((6*$L+4)*4**$level - 4) / 3;
      my ($x,$y) = $path->n_to_xy($Nlevel);
      my $Xlevel = ($L+2)*2**$level - 1;
      $x == $Xlevel or die "x=$x Xlevel=$Xlevel";
      my $frac = $Nlevel / ($x*($x-1)/2);
      print "  $level  $frac\n";
    }
    my $nf = Number::Fraction->new((12*$L+8),(3*$L**2+12*$L+12));
    my $limit = $nf->to_num;
    print "  limit  $nf = $limit\n";
  }
  exit 0;
}

{
  my $path = Math::PlanePath::SierpinskiCurve->new;
  my @rows = ((' ' x 79) x 64);
  foreach my $n (0 .. 3 * 3**4) {
    my ($x, $y) = $path->n_to_xy ($n);
    $x += 32;
    substr ($rows[$y], $x,1, '*');
  }
  local $,="\n";
  print reverse @rows;
  exit 0;
}

{
  my @rows = ((' ' x 64) x 32);
  foreach my $p (0 .. 31) {
    foreach my $q (0 .. 31) {
      next if ($p & $q);

      my $x = $p-$q;
      my $y = $p+$q;
      next if ($y >= @rows);
      $x += 32;
      substr ($rows[$y], $x,1, '*');
    }
  }
  local $,="\n";
  print reverse @rows;
  exit 0;
}
