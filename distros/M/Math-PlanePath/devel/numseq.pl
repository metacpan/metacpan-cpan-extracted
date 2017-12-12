#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2017 Kevin Ryde

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
use Math::Trig 'pi';

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # max turn Left etc

  require Math::NumSeq::PlanePathTurn;
  require Math::NumSeq::PlanePathDelta;
  my $planepath;
  $planepath = "TerdragonMidpoint,arms=6";
  $planepath = "AnvilSpiral,wider=17";
  $planepath = "QuintetCurve,arms=4";
  $planepath = "OneOfEight,parts=wedge";
  $planepath = "LCornerTree,parts=diagonal-1";
  $planepath = "UlamWarburton,parts=octant_up";
  $planepath = "TriangularHypot,points=hex_rotated";
  $planepath = "TriangularHypot,points=hex_centred";
  $planepath = "TriangularHypot,points=hex";
  $planepath = "TriangularHypot,points=even";
  $planepath = "PixelRings";
  $planepath = "FilledRings";
  $planepath = "MultipleRings,step=9,shape=polygon,n_start=0";
  $planepath = "ChanTree,k=11,reduced=1";
  $planepath = "DigitGroups,radix=5";
  $planepath = "CfracDigits,radix=37";
  $planepath = "GrayCode,radix=37";
  $planepath = "CellularRule,rule=8";
  $planepath = "LCornerTree,parts=1";
  my $seq = Math::NumSeq::PlanePathTurn->new (planepath => $planepath,
                                              turn_type => 'LSR');

  # $planepath = "FractionsTree";
  # my $seq = Math::NumSeq::PlanePathDelta->new (planepath => $planepath,
  #                                             delta_type => 'Dir4');
  my $max = -99;
  my $min = 99;
  my $prev_i = undef;
  my %seen;
  for (1 .. 1000000) {
    my ($i, $value) = $seq->next;
    if (! defined $i) {
      print "no more values after i=$prev_i\n";
      last;
    }
    # $value = -$value; next unless $value;

    if (! $seen{$value}++) {
      printf "%d %s new value\n", $i, $value;
    }
    # if ($value > $max) {
    #   printf "%d %.5f new max\n", $i, $value;
    #   $max = $value;
    # }
    # if ($value < $min) {
    #   printf "%d %.5f new min\n", $i, $value;
    #   $min = $value;
    # }
    $prev_i = $i;
  }
  exit 0;
}
{
  # when X neg, Y neg
  require Math::NumSeq::PlanePathCoord;
  my $planepath;
  $planepath = "AR2W2Curve,start_shape=A2rev";
  $planepath = "BetaOmega,arms=1";
  $planepath = "Math::PlanePath::SierpinskiArrowhead";
  $planepath = "Math::PlanePath::FlowsnakeCentres,arms=1";
  $planepath = "GosperSide";
  $planepath = "FlowsnakeCentres,arms=3";
  $planepath = "HexSpiral,wider=10";
  $planepath = "Math::PlanePath::QuintetCentres,arms=1";
  $planepath = "Math::PlanePath::R5DragonCurve,arms=1";
  $planepath = "Math::PlanePath::R5DragonMidpoint,arms=2";
  $planepath = "Math::PlanePath::AlternatePaper,arms=5";
  $planepath = "ComplexPlus";
  print "$planepath\n";
  my $seq = Math::NumSeq::PlanePathCoord->new (planepath => $planepath);
  my $path = $seq->{'planepath_object'};
  my ($x_negative_at_n, $y_negative_at_n, $sum_negative_at_n);
  for (my $n = $path->n_start; ; $n++) {
    my ($x,$y) = $path->n_to_xy($n);
    if ($x < 0 && ! defined $x_negative_at_n) {
      $x_negative_at_n = $n;
      print "X negative $x_negative_at_n\n";
    }
    if ($y < 0 && ! defined $y_negative_at_n) {
      $y_negative_at_n = $n;
      print "Y negative $y_negative_at_n\n";
    }
    my $sum = $x+$y;
    if ($sum < 0 && ! defined $sum_negative_at_n) {
      $sum_negative_at_n = $n;
      print "Sum negative $sum_negative_at_n\n";
    }
    last if defined $x_negative_at_n && defined $y_negative_at_n
      && defined $sum_negative_at_n;
  }
  exit 0;
}

{
  require Math::NumSeq::PlanePathCoord;
  foreach my $path_type (@{Math::NumSeq::PlanePathCoord->parameter_info_array->[0]->{'choices'}}) {
    my $class = "Math::PlanePath::$path_type";
    ### $class
    eval "require $class; 1" or die;
    my @pinfos = $class->parameter_info_list;
    my $params = parameter_info_list_to_parameters(@pinfos);

  PAREF:
    foreach my $paref (@$params) {
      ### $paref
      my $path = $class->new(@$paref);
      my $seq = Math::NumSeq::PlanePathCoord->new(planepath_object => $path,
                                                  coordinate_type => 'Sum');

      foreach (1 .. 10) {
        $seq->next;
      }
      foreach (1 .. 1000) {
        my ($i, $value) = $seq->next;
        if (! defined $i || $value < $i) {
          next PAREF;
        }
      }
      print "$path_type ",join(',',@$paref),"\n";
    }
  }
  exit 0;

  sub parameter_info_list_to_parameters {
    my @parameters = ([]);
    foreach my $info (@_) {
      info_extend_parameters($info,\@parameters);
    }
    return \@parameters;
  }

  sub info_extend_parameters {
    my ($info, $parameters) = @_;
    my @new_parameters;

    if ($info->{'name'} eq 'planepath') {
      my @strings;
      foreach my $choice (@{$info->{'choices'}}) {
        my $path_class = "Math::PlanePath::$choice";
        Module::Load::load($path_class);

        my @parameter_info_list = $path_class->parameter_info_list;

        if ($path_class->isa('Math::PlanePath::Rows')) {
          push @parameter_info_list,{ name       => 'width',
                                      type       => 'integer',
                                      width      => 3,
                                      default    => '1',
                                      minimum    => 1,
                                    };
        }
        if ($path_class->isa('Math::PlanePath::Columns')) {
          push @parameter_info_list, { name       => 'height',
                                       type       => 'integer',
                                       width      => 3,
                                       default    => '1',
                                       minimum    => 1,
                                     };
        }

        my $path_parameters
          = parameter_info_list_to_parameters(@parameter_info_list);
        ### $path_parameters

        foreach my $aref (@$path_parameters) {
          my $str = $choice;
          while (@$aref) {
            $str .= "," . shift(@$aref) . '=' . shift(@$aref);
          }
          push @strings, $str;
        }
      }
      ### @strings
      foreach my $p (@$parameters) {
        foreach my $choice (@strings) {
          push @new_parameters, [ @$p, $info->{'name'}, $choice ];
        }
      }
      @$parameters = @new_parameters;
      return;
    }

    if ($info->{'name'} eq 'arms') {
      print "  skip parameter $info->{'name'}\n";
      return;
    }

    if ($info->{'choices'}) {
      my @new_parameters;
      foreach my $p (@$parameters) {
        foreach my $choice (@{$info->{'choices'}}) {
          next if ($info->{'name'} eq 'rotation_type' && $choice eq 'custom');
          push @new_parameters, [ @$p, $info->{'name'}, $choice ];
        }
      }
      @$parameters = @new_parameters;
      return;
    }

    if ($info->{'type'} eq 'boolean') {
      my @new_parameters;
      foreach my $p (@$parameters) {
        foreach my $choice (0, 1) {
          push @new_parameters, [ @$p, $info->{'name'}, $choice ];
        }
      }
      @$parameters = @new_parameters;
      return;
    }

    if ($info->{'type'} eq 'integer'
        || $info->{'name'} eq 'multiples') {
      ### $info
      my $max = ($info->{'minimum'}||-5)+10;
      if ($info->{'name'} eq 'straight_spacing') { $max = 2; }
      if ($info->{'name'} eq 'diagonal_spacing') { $max = 2; }
      if ($info->{'name'} eq 'radix') { $max = 17; }
      if ($info->{'name'} eq 'realpart') { $max = 3; }
      if ($info->{'name'} eq 'wider') { $max = 3; }
      if ($info->{'name'} eq 'modulus') { $max = 32; }
      if ($info->{'name'} eq 'polygonal') { $max = 32; }
      if ($info->{'name'} eq 'factor_count') { $max = 12; }
      if (defined $info->{'maximum'} && $max > $info->{'maximum'}) {
        $max = $info->{'maximum'};
      }
      if ($info->{'name'} eq 'power' && $max > 6) { $max = 6; }
      my @new_parameters;
      foreach my $choice (($info->{'minimum'}||0) .. $max) {
        foreach my $p (@$parameters) {
          push @new_parameters, [ @$p, $info->{'name'}, $choice ];
        }
      }
      @$parameters = @new_parameters;
      return;
    }

    if ($info->{'name'} eq 'fraction') {
      ### fraction ...
      my @new_parameters;
      foreach my $p (@$parameters) {
        my $radix = p_radix($p) || die;
        foreach my $den (995 .. 1021) {
          next if $den % $radix == 0;
          my $choice = "1/$den";
          push @new_parameters, [ @$p, $info->{'name'}, $choice ];
        }
        foreach my $num (2 .. 10) {
          foreach my $den ($num+1 .. 15) {
            next if $den % $radix == 0;
            next unless _coprime($num,$den);
            my $choice = "$num/$den";
            push @new_parameters, [ @$p, $info->{'name'}, $choice ];
          }
        }
      }
      @$parameters = @new_parameters;
      return;
    }

    print "  skip parameter $info->{'name'}\n";
  }

}

{
  # max Dir4

  require Math::BaseCnv;

  # print 4-atan2(2,1)/atan2(1,1)/2,"\n";

  require Math::NumSeq::PlanePathDelta;
  require Math::NumSeq::PlanePathTurn;
  my $realpart = 3;
  my $radix = $realpart*$realpart + 1;
  my $planepath;
  $planepath = "RationalsTree,tree_type=Drib";
  $planepath = "GosperReplicate";
  $planepath = "QuintetReplicate";
  $planepath = "RationalsTree,tree_type=HCS";
  $planepath = "ToothpickReplicate,parts=1";
  $planepath = "CfracDigits,radix=2";
  $planepath = "DiagonalRationals,direction=up";
  $planepath = "OneOfEight,parts=wedge";
  $planepath = "QuadricIslands";
  $planepath = "WunderlichSerpentine";
  $planepath = "ComplexMinus,realpart=3";
  $planepath = "UlamWarburton,parts=4";
  $planepath = "ToothpickTreeByCells,parts=two_horiz";
  $planepath = "LCornerTreeByCells,parts=octant_up+1";
  $planepath = "ChanTree,k=5";
  $planepath = "ComplexPlus,realpart=2";
  $planepath = "CfracDigits,radix=".($radix-1);
  $planepath = "GosperIslands";
  $planepath = "ImaginaryHalf"; # ,digit_order=XnXY";
  $planepath = "SquareReplicate";
  $planepath = "GrayCode,radix=$radix,apply_type=Ts";
  $planepath = "SquareReplicate";
  $planepath = "ToothpickTree,parts=2";
  $planepath = "ToothpickUpist";
  $planepath = "CornerReplicate";
  $radix = 3;
  $planepath = "ZOrderCurve,radix=$radix";
  $planepath = "LCornerReplicate";
  $planepath = "LCornerTree,parts=diagonal-1";
  $planepath = "PowerArray,radix=$radix";
  $planepath = "DigitGroups,radix=$radix";
  $planepath = "FactorRationals,sign_encoding=negabinary";
  $planepath = "GcdRationals,pairs_order=diagonals_up";
  $planepath = "LTiling";
  $planepath = "TriangularHypot,points=hex_rotated";
  $planepath = "Hypot,points=all";
  $planepath = "MultipleRings,step=3";
  $planepath = "ArchimedeanChords";
  $planepath = "DragonMidpoint";
  $planepath = "HexSpiral,wider=1";
  $planepath = "AlternatePaper";
  $planepath = "VogelFloret";
  $planepath = "MultipleRings,step=6,ring_shape=polygon";
  $planepath = "PythagoreanTree,coordinates=MC,tree_type=UMT";
  $planepath = "R5DragonMidpoint";
  $planepath = "OctagramSpiral";
  $planepath = "Columns,height=6";
  $planepath = "SacksSpiral";
  $planepath = "CellularRule,rule=6";
  $planepath = "Z2DragonCurve";
  $planepath = "WythoffPreliminaryTriangle";
  $planepath = "UlamWarburton,parts=octant";
  my $seq = Math::NumSeq::PlanePathDelta->new (planepath => $planepath,
                                               # delta_type => 'dX',
                                               delta_type => 'Dir4',
                                               # delta_type => 'dTRadius',
                                               # delta_type => 'dRSquared',
                                               # delta_type => 'dDiffXY',
                                               # delta_type => 'TDir6',
                                               # delta_type => 'dAbsDiff',
                                              );

  my $dx_seq = Math::NumSeq::PlanePathDelta->new (planepath => $planepath,
                                                  delta_type => 'dX');
  my $dy_seq = Math::NumSeq::PlanePathDelta->new (planepath => $planepath,
                                                  delta_type => 'dY');
  # my $seq = Math::NumSeq::PlanePathTurn->new (planepath => $planepath,
  #                                             turn_type => 'Turn4',
  #                                            );

  # my $dx_seq = Math::NumSeq::PlanePathCoord->new (planepath => $planepath,
  #                                                 coordinate_type => 'X');
  # my $dy_seq = Math::NumSeq::PlanePathCoord->new (planepath => $planepath,
  #                                                 coordinate_type => 'Y');
  my $min = 99;
  my $max = -99;
  for (1 .. 10_000_000) {
    my ($i, $value) = $seq->next;
    # $seq->seek_to_i(2*$i+2);

    if ($value > $max) {
      my $dx = $dx_seq->ith($i);
      my $dy = $dy_seq->ith($i);
      my $prev_dx = $dx_seq->ith($i-1) // 'u';
      my $prev_dy = $dy_seq->ith($i-1) // 'u';
      my $ri = Math::BaseCnv::cnv($i,10,$radix);
      my $rdx = Math::BaseCnv::cnv($dx,10,$radix);
      my $rdy = Math::BaseCnv::cnv($dy,10,$radix);
      my $f = $dy && $dx/$dy;
      $max = $value;
      printf "max i=%d[%s] %.5f  px=%s,py=%s dx=%s,dy=%s[%s,%s]   %.3f\n",
        $i,$ri, $value,
          $prev_dx,$prev_dy,
            $dx,$dy, $rdx,$rdy, $f;
    }

    if ($value < $min) {
      my $dx = $dx_seq->ith($i);
      my $dy = $dy_seq->ith($i);
      my $prev_dx = $dx_seq->ith($i-1) // 'u';
      my $prev_dy = $dy_seq->ith($i-1) // 'u';
      my $ri = Math::BaseCnv::cnv($i,10,$radix);
      my $rdx = Math::BaseCnv::cnv($dx,10,$radix);
      my $rdy = Math::BaseCnv::cnv($dy,10,$radix);
      my $f = $dy && $dx/$dy;
      $min = $value;
      printf " min i=%d[%s] %.5f  px=%s,py=%s dx=%s,dy=%s   %.3f\n",
        $i,$ri, $value,
          $prev_dx,$prev_dy,
            $dx,$dy, $f;
      my $slope_dy_dx = ($dx == 0 ? 0 : $dy/$dx);
      printf "     dy/dx=%.5f\n", $slope_dy_dx;
    }
  }

  exit 0;
}

{
  # dx,dy seen
  require Math::NumSeq::PlanePathCoord;
  my $planepath = "CellularRule,rule=2";
  $planepath = "AR2W2Curve,start_shape=A2rev";
  $planepath = "BetaOmega,arms=1";
  $planepath = "Math::PlanePath::SierpinskiArrowhead";
  $planepath = "PixelRings";
  $planepath = "DiamondArms";
  $planepath = "Math::PlanePath::QuintetCurve,arms=1";
  $planepath = "Math::PlanePath::GreekKeySpiral,turns=3";
  $planepath = "WunderlichSerpentine,radix=5,serpentine_type=coil";
  $planepath = "KnightSpiral";
  print "$planepath\n";
  my $seq = Math::NumSeq::PlanePathCoord->new (planepath => $planepath);
  my $path = $seq->{'planepath_object'};
  my %seen_dxdy;
  for (my $n = $path->n_start; ; $n++) {
    my ($dx,$dy) = $path->n_to_dxdy($n);
    unless ($seen_dxdy{"$dx,$dy"}++) {
      my $desc = ($dx == 1 && $dy == 0 ? 'E'
                  : $dx == 2 && $dy == 0 ? 'E'
                  : $dx == -1 && $dy == 0 ? 'W'
                  : $dx == -2 && $dy == 0 ? 'W'
                  : $dx == 0 && $dy == 1 ? 'N'
                  : $dx == 0 && $dy == -1 ? 'S'
                  : $dx == 1 && $dy == 1 ? 'NE'
                  : $dx == -1 && $dy == 1 ? 'NW'
                  : $dx == 1 && $dy == -1 ? 'SE'
                  : $dx == -1 && $dy == -1 ? 'SW'
                  : '');
      print "$dx,$dy,   # $desc  N=$n\n";
    }
  }
  exit 0;
}

{
  # min/max PlanePathCoord

  require Math::BaseCnv;

  require Math::NumSeq::PlanePathCoord;
  my $realpart = 3;
  my $radix = $realpart*$realpart + 1;
  my $planepath;
  $planepath = "MultipleRings,step=3";
  $planepath = "MultipleRings,step=3,ring_shape=polygon";
  my $seq = Math::NumSeq::PlanePathCoord->new (planepath => $planepath,
                                               coordinate_type => 'AbsDiff');
  my $path = $seq->{'planepath_object'};
  my $min = 99;
  my $max = -99;
  for (1 .. 10000000) {
    my ($i, $value) = $seq->next;

    # if ($value > $max) {
    #   my $dx = $dx_seq->ith($i);
    #   my $dy = $dy_seq->ith($i);
    #   my $prev_dx = $dx_seq->ith($i-1) // 'u';
    #   my $prev_dy = $dy_seq->ith($i-1) // 'u';
    #   my $ri = Math::BaseCnv::cnv($i,10,$radix);
    #   my $rdx = Math::BaseCnv::cnv($dx,10,$radix);
    #   my $rdy = Math::BaseCnv::cnv($dy,10,$radix);
    #   my $f = $dy && $dx/$dy;
    #   $max = $value;
    #   printf "max i=%d[%s] %.5f  px=%s,py=%s dx=%s,dy=%s[%s,%s]   %.3f\n",
    #     $i,$ri, $value,
    #       $prev_dx,$prev_dy,
    #         $dx,$dy, $rdx,$rdy, $f;
    # }

    if ($value < $min) {
      my ($x,$y) = $path->n_to_xy($i);
      $min = $value;
      my $ri = Math::BaseCnv::cnv($i,10,$radix);
      printf " min i=%d[%s] %.5f  x=%s,y=%s\n",
        $i,$ri, $value, $x,$y;
    }
  }

  exit 0;
}

{
  require Math::NumSeq::PlanePathDelta;
  for (my $a = 0; $a <= 360; $a += 5) {
    print "$a  ",Math::NumSeq::PlanePathDelta::_dir360_to_tdir6($a),"\n";
  }
  exit 0;
}


{
  # kronecker cf A215200
  require Math::NumSeq::PlanePathCoord;
  foreach my $n (1 .. 10) {
    foreach my $k (1 .. $n) {
      my $x = $n - $k;
      my $y = $k;
      my $kron = Math::NumSeq::PlanePathCoord::_kronecker_symbol($x,$y);
      printf "%3d,", $kron;
    }
    print "\n";
  }
  exit 0;
}

{
  # axis increasing
  my $radix = 4;
  my $rsquared = $radix * $radix;
  my $re = '.' x $radix;

  require Math::NumSeq::PlanePathN;
  my $planepath;
  $planepath = "AlternatePaperMidpoint,arms=7";
  $planepath = "ImaginaryBase,radix=37";
  $planepath = "ImaginaryHalf,radix=37";
  $planepath = "DekkingCurve";
  $planepath = "DekkingCentres";
  $planepath = "LCornerReplicate";
  $planepath = "LCornerTree,parts=3";
 LINE_TYPE: foreach my $line_type ('X_axis',
                                   'Y_axis',
                                   'X_neg',
                                   'Y_neg',
                                   'Diagonal_SE',
                                   'Diagonal_SW',
                                   'Diagonal_NW',
                                   'Diagonal',
                                  ) {
    my $seq = Math::NumSeq::PlanePathN->new
      (
       planepath => $planepath,
       line_type => $line_type,
      );
    ### $seq

    my $i_start = $seq->i_start;
    my $prev_value = -1;
    my $prev_i = -1;
    my $i_limit = 10000;
    my $i_end = $i_start + $i_limit;
    for my $i ($i_start .. $i_end) {
      my $value = $seq->ith($i);
      next if ! defined $value;
      ### $value
      if ($value <= $prev_value) {
        # print "$line_type_type   decrease at i=$i  value=$value cf prev=$prev\n";
        my $path = $seq->{'planepath_object'};
        my ($prev_x,$prev_y) = $path->n_to_xy($prev_value);
        my ($x,$y) = $path->n_to_xy($value);
        print "$line_type not   N=$prev_value $prev_x,$prev_y  N=$value $x,$y\n";
        next LINE_TYPE;
      }
      $prev_i = $i;
      $prev_value = $value;
    }
    print "$line_type   all increasing (to i=$prev_i)\n";
  }
  exit 0;
}

{
  # PlanePathCoord increasing
  require Math::NumSeq::PlanePathCoord;
  my $planepath;
  $planepath = "SierpinskiTriangle,align=right";
 COORDINATE_TYPE: foreach my $coordinate_type ('BitAnd',
                                               'BitOr',
                                               'BitXor',
                                              ) {
    my $seq = Math::NumSeq::PlanePathCoord->new
      (
       planepath => $planepath,
       coordinate_type => $coordinate_type,
      );
    ### $seq

    my $i_start = $seq->i_start;
    my $prev_value;
    my $prev_i;
    my $i_limit = 100000;
    my $i_end = $i_start + $i_limit;
    for my $i ($i_start .. $i_end) {
      my $value = $seq->ith($i);
      next if ! defined $value;
      ### $i
      ### $value
      if (defined $prev_value && $value < $prev_value) {
        # print "$coordinate_type_type   decrease at i=$i  value=$value cf prev=$prev\n";
        my $path = $seq->{'planepath_object'};
        my ($prev_x,$prev_y) = $path->n_to_xy($prev_value);
        my ($x,$y) = $path->n_to_xy($value);
        print "$coordinate_type not i=$i value=$value cf prev_value=$prev_value\n";
        next COORDINATE_TYPE;
      }
      $prev_i = $i;
      $prev_value = $value;
    }
    print "$coordinate_type   all increasing (to i=$prev_i)\n";
  }
  exit 0;
}

{
  require Math::BigInt;
  my $x = Math::BigInt->new(8);
  my $y = Math::BigInt->new(-2);
  $x = (8);
  $y = (-2);
  my $z = $x ^ $y;
  print "$z\n";
  printf "%b\n", $z & 0xFFF;
  if ((($x<0) ^ ($y<0)) != ($z<0)) {
    $z = Math::BigInt->new("$z");
    $z = ($z - (1<<63)) + -(1<<63);
  }
  print "$z\n";
  printf "%b\n", $z & 0xFFF;

  sub sign_extend {
    my ($n) = @_;
    return ($n - (1<<63)) + -(1<<63);
  }
  exit 0;
}

{
  my $pi = pi();
  my %seen;
  foreach my $x (0 .. 100) {
    foreach my $y (0 .. 100) {
      my $factor;

      $factor = 1;

      $factor = sqrt(3);
      # next unless ($x&1) == ($y&1);

      $factor = sqrt(8);

      my $radians = atan2($y*$factor, $x);
      my $degrees = $radians / $pi * 180;
      my $frac = $degrees - int($degrees);
      if ($frac > 0.5) {
        $frac -= 1;
      }
      if ($frac < -0.5) {
        $frac += 1;
      }
      my $int = $degrees - $frac;
      next if $seen{$int}++;

      if ($frac > -0.001 && $frac < 0.001) {
        print "$x,$y   $int  ($degrees)\n";
      }
    }
  }
  exit 0;
}
