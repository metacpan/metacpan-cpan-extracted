#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2019 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# DragonCurve,arms=2 boundary (by powers full diffs all):
# 20,28,52,92,148,252,436,732,1236,2108,3572,6044
# match 20,28,52,92,148,252,436,732,1236,2108,3572,6044
# [HALF]
# A052537 Expansion of (1-x)/(1-x-2x^3).
# A052537 ,1,0,0,2,2,2,6,10,14,26,46,74,126,218,366,618,1054,1786,3022,5130,8702,14746,25006,42410,71902,121914,206734,350538,594366,1007834,1708910,2897642,4913310,8331130,14126414,23953034,40615294,68868122,116774190,198004778,

# Rationals tree inter-row area
# 2*area = A048487 a(n) = 5*2^n-4     T(4,n), array T given by A048483.
# area = A051633 5*2^n - 2.
# same A131051 Row sums of triangle A133805.
# A126284 5*2^n-4*n-5  total*2
#
# alt paper
# A129284 A129150(n) / 4.
# A129285 A129151(n) / 27.

# Math::PlanePath::GosperReplicate unit hexagons boundary length
# A178674 = 3^n+3


use 5.010;
use strict;
use List::Util 'min', 'max';
use Module::Load;
use Math::Libm 'hypot';
use List::Pairwise;
use Math::BaseCnv;

use lib 'xt';
use MyOEIS;
use Math::OEIS::Grep;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # net direction as total turn

  require Math::NumSeq::PlanePathTurn;
  my @choices = @{Math::NumSeq::PlanePathTurn->parameter_info_hash
      ->{'planepath'}->{'choices'}};
  @choices = grep {$_ ne 'BinaryTerms'} @choices; # bit slow yet
  @choices = grep {$_ =~ /Curve/} @choices;

  my @turn_type_choices = @{Math::NumSeq::PlanePathTurn->parameter_info_hash
      ->{'turn_type'}->{'choices'}};
  push @turn_type_choices,  'Turn4','Turn4n', 'TTurn6', 'TTurn6n', 'TTurn3';

  # force
  # @turn_type_choices = 'TTurn3';

  # force
  # @choices = ('ComplexMinus');

  my %seen;
  foreach my $path_name (@choices) {
    my $path_class = "Math::PlanePath::$path_name";
    Module::Load::load($path_class);
    my $parameters = parameter_info_list_to_parameters($path_class->parameter_info_list);
  PATH: foreach my $p ([],      # paths with no parameters
                       # @$parameters
                      ) {
      print "\n$path_class  ",join(',',@$p),"\n";
      my $path = $path_class->new (@$p);

      foreach my $turn_type (@turn_type_choices) {
        my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                    turn_type => $turn_type);
        print "$turn_type\n";

        my $name = "$path_name $turn_type  ".join(',',@$p);
        my $dir = 0;
        my @values;
        my $all_zeros = 1;
        my $all_ones = 1;
        foreach (1 .. 40) {
          push @values, $dir;
          my ($i,$value) = $seq->next or last;
          $dir += $value;
          if ($value != 0) { $all_zeros = 0; }
          if ($value != 1) { $all_ones = 0; }
        }
        next if $all_zeros || $all_ones;
        shift @values; shift @values;
        next unless @values;

        print "$turn_type  ",join(', ',@values),"\n";
        Math::OEIS::Grep->search(name => $name,
                                 array => \@values);
      }
    }
  }
  exit 0;
}

{
  # N on axes

  my @dir8_to_dx = (1, 1, 0,-1, -1, -1,  0, 1);
  my @dir8_to_dy = (0, 1, 1, 1,  0, -1, -1,-1);
  my @dir8_to_line_type = ("X_axis",
                           "Diagonal",
                           "Y_axis",
                           "Diagonal_NW",
                           "X_neg",
                           "Diagonal_SW",
                           "Y_neg",
                           "Diagonal_SE");

  require Math::NumSeq::PlanePathCoord;
  require Math::NumSeq::PlanePathN;
  my @choices = @{Math::NumSeq::PlanePathCoord->parameter_info_hash
      ->{'planepath'}->{'choices'}};
  @choices = grep {$_ ne 'BinaryTerms'} @choices; # bit slow yet
  @choices = grep {$_ =~ /Gray/} @choices;

  # force
  # @choices = ('ComplexMinus');

  my %seen;
  foreach my $path_name (@choices) {
    print "$path_name\n";
    my $path_class = "Math::PlanePath::$path_name";
    Module::Load::load($path_class);
    my $parameters = parameter_info_list_to_parameters($path_class->parameter_info_list);
  PATH: foreach my $p (@$parameters) {
      my $path = $path_class->new (@$p);

      foreach my $dir (0 .. 7) {
        my $line_type = $dir8_to_line_type[$dir];
        my $seq = Math::NumSeq::PlanePathN->new (planepath_object => $path,
                                                 line_type => $line_type);
        my $anum = $seq->oeis_anum;
        print "$line_type seq anum ",($anum//'undef'),"\n";
        next if defined $anum;

        my $name = "$path_name dir=$dir  ".join(',',@$p);
        my $dx = $dir8_to_dx[$dir];
        my $dy = $dir8_to_dy[$dir];
        my $x = 2*$dx;
        my $y = 2*$dy;
        my @values;
        foreach my $i (4 .. 30) {
          my $value = $path->xy_to_n($x,$y) // last;
          push @values, $value;
          $x += $dx;
          $y += $dy;
        }
        next unless @values;
        Math::OEIS::Grep->search(name => $name,
                                      array => \@values);
      }
    }
  }
  exit 0;
}
{
  # X,Y at N=2^k
  require Math::NumSeq::PlanePathCoord;
  my @choices = @{Math::NumSeq::PlanePathCoord->parameter_info_hash
      ->{'planepath'}->{'choices'}};
  @choices = grep {$_ ne 'CellularRule'} @choices;
  # @choices = grep {$_ ne 'Rows'} @choices;
  # @choices = grep {$_ ne 'Columns'} @choices;
  @choices = grep {$_ ne 'ArchimedeanChords'} @choices;
  @choices = grep {$_ ne 'TheodorusSpiral'} @choices;
  @choices = grep {$_ ne 'MultipleRings'} @choices;
  @choices = grep {$_ ne 'VogelFloret'} @choices;
  @choices = grep {$_ ne 'UlamWarburtonAway'} @choices;
  @choices = grep {$_ !~ /Hypot|ByCells|SumFractions|WythoffTriangle/} @choices;
  # @choices = grep {$_ ne 'PythagoreanTree'} @choices;
  # @choices = grep {$_ ne 'PeanoHalf'} @choices;
  @choices = grep {$_ !~ /EToothpick|LToothpick|Surround|Peninsula/} @choices;
  #
  # @choices = grep {$_ ne 'CornerReplicate'} @choices;
   @choices = grep {$_ ne 'HilbertSides'} @choices;
  unshift @choices, 'HilbertSides';

  my $num_choices = scalar(@choices);
  print "$num_choices choices\n";

  my @path_objects;
  my %path_fullnames;
  foreach my $name (@choices) {
    my $class = "Math::PlanePath::$name";
    ### $class
    Module::Load::load($class);

    my $parameters = parameter_info_list_to_parameters
      ($class->parameter_info_list);
    foreach my $p (@$parameters) {
      my $path_object = $class->new (@$p);
      push @path_objects, $path_object;
      $path_fullnames{$path_object} = "$name ".join(',',@$p);
    }
  }
  my $num_path_objects = scalar(@path_objects);
  print "total path objects $num_path_objects\n";

  my $start_t = time();
  my $t = $start_t-8;

  my $i = 0;
  # until ($path_objects[$i]->isa('Math::PlanePath::TerdragonCurve')) {
  #   $i++;
  # }

  for ( ; $i <= $#path_objects; $i++) {
    my $path = $path_objects[$i];
    my $fullname = $path_fullnames{$path};
    print "$fullname\n";
    foreach my $coord_idx (0, 1) {
      my $fullname = $fullname." ".($coord_idx?'Y':'X');
      my @values;
      for (my $k = Math::BigInt->new(1); $k <= 12; $k++) {
        my ($n_lo, $n_hi) = $path->level_to_n_range($k);
        $n_hi //= 2**$k;
        my @coords = $path->n_to_xy($n_hi);
        my $value = $coords[$coord_idx];
        push @values, $value;
      }
      shift @values;
      Math::OEIS::Grep->search(array => \@values, name => $fullname);
    }
  }
  exit 0;
}

{
  # single, double, triple visited counts in levels

  require Math::NumSeq::PlanePathCoord;
  foreach my $elem (
                    # curves with overlaps only
                    ['HilbertSides',   2],
                    ['TerdragonCurve', 3],
                    ['R5DragonCurve',  5],
                    ['AlternatePaper', 4],
                    ['AlternatePaper', 2],
                    ['CCurve',         2],
                    ['DragonCurve',    2],
                   ) {
    my ($name, $radix) = @$elem;

    print "$name\n";
    my $path = Math::NumSeq::PlanePathCoord::_planepath_name_to_object($name);
    my $n_start = $path->n_start;

    my (@singles, @doubles, @triples);
    foreach my $inc_type ('powers') {
      for (my $level = 3; ; $level++) {
        my $n_end = $radix**$level;
        last if $n_end > 20_000;
        last if @singles > 25;

        my @counts = path_n_to_visit_counts($path, $n_end);
        push @singles, $counts[0] || 0;
        push @doubles, $counts[1] || 0;
        push @triples, $counts[2] || 0;

        print "$level $n_end  $singles[-1] $doubles[-1] $triples[-1]\n";
      }
      {
        shift_off_zeros(\@singles);
        print join(',',@singles),"\n";
        Math::OEIS::Grep->search(array => \@singles,
                                      name => 'singles');
      }
      {
        shift_off_zeros(\@doubles);
        print join(',',@doubles),"\n";
        Math::OEIS::Grep->search(array => \@doubles,
                                      name => 'doubles');
      }
      if ($triples[-1]) {
        shift_off_zeros(\@triples);
        print join(',',@triples),"\n";
        Math::OEIS::Grep->search(array => \@triples,
                                      name => 'triples');
      }
      print "\n";
    }
  }
  exit 0;

  sub path_n_to_visit_counts {
    my ($path, $n_end) = @_;
    my @counts;
    foreach my $n ($path->n_start .. $n_end) {
      my @n_list = $path->n_to_n_list($n);
      if ($n_list[0] == $n) {
        @n_list = grep {$_<=$n_end} @n_list;
        $counts[scalar(@n_list)]++;
      }
    }
    shift @counts;
    return @counts;
  }
}

{
  # X,Y repeat count
  require Math::NumSeq::PlanePathCoord;
  foreach my $elem (
                    # curves with overlaps only
                    ['HilbertSides', 2],
                    ['DragonCurve', 2],
                    ['R5DragonCurve', 5],
                    ['CCurve', 2],
                    ['TerdragonCurve', 3, 'triangular'],
                    ['AlternatePaper', 4],
                    ['AlternatePaper', 2],
                   ) {
    my ($name, $radix, $lattice_type) = @$elem;
    $lattice_type ||= 'square';
    my $path = Math::NumSeq::PlanePathCoord::_planepath_name_to_object($name);

    print "$name\n";
    {
      my @values;
      foreach my $n (15 .. 40) {
        my @n_list = $path->n_to_n_list($n);
        my $count = scalar(@n_list);
        push @values, $count;
      }
      print "\n$name counts:\n";
      shift_off_zeros(\@values);
      print join(',',@values),"\n";
      Math::OEIS::Grep->search(array => \@values);
      array_diffs(\@values);
      Math::OEIS::Grep->search(array => \@values, name => "diffs");
    }
    if (0) {
      my @values;
      foreach my $level (3 .. 8) {
        my $count = 0;
        my $n_hi = $radix**($level+1) - 1;
        last if $n_hi > 50_000;
        foreach my $n ($radix**$level .. $n_hi) {
          my @n_list = $path->n_to_n_list($n);
          $count += scalar(@n_list);
        }
        push @values, $count;
      }
      # if ($diffs) {
      #   foreach my $i (reverse 1 .. $#areas) {
      #     $areas[$i] -= $areas[$i-1];
      #   }
      print "\n$name total in powers $radix\n";
      shift_off_zeros(\@values);
      print join(',',@values),"\n";
      Math::OEIS::Grep->search(array => \@values);
      print "\n";
      array_diffs(\@values);
      Math::OEIS::Grep->search(array => \@values, name => "diffs");
    }
  }
  exit 0;

  sub array_diffs {
    my ($aref) = @_;
    foreach my $i (0 .. $#$aref-1) {
      $aref->[$i] = $aref->[$i+1] - $aref->[$i];
    }
    $#$aref--;
  }
}
{
  # NSEW segment counts
  # AlternatePaper  A005418, A051437, A122746=A032085, A007179
  #   cf Wests A122746 = area increment
  #
  my $radix = 2;
  my $name = 'Math::PlanePath::CCurve';
  $name = 'Math::PlanePath::AlternatePaper';
  $name = 'Math::PlanePath::DragonCurve'; #  A038503, A038504, A038505, A000749 same CCurve
  $name = 'Math::PlanePath::DragonMidpoint'; # x, x, 2*A038505, 2*A000749
  $name = 'Math::PlanePath::TerdragonMidpoint'; $radix=3; # none
  $name = 'Math::PlanePath::PeanoCurve'; $radix=3;
  $name = 'Math::PlanePath::BetaOmega'; $radix=2;
  $name = 'Math::PlanePath::KochelCurve'; $radix=2;
  $name = 'Math::PlanePath::CincoCurve'; $radix=25;
  $name = 'Math::PlanePath::WunderlichMeander'; $radix=3; # none
  $name = 'Math::PlanePath::KochCurve'; $radix=4; # a=A087433,b,c=2*A081674,d,e=A081674,x
  $name = 'Math::PlanePath::KochCurve'; $radix=2; # a=A036557,e=A000773
  $name = 'Math::PlanePath::DekkingCentres'; $radix=25;  # NE=NW=SW=SE=A218728=sum 25^i
  $name = 'Math::PlanePath::HIndexing'; $radix=4; # A007583,A079319,A020988=(2/3)*(4^n-1),2*A006095
  $name = 'Math::PlanePath::QuintetCurve'; $radix=5; # QuintetCentres
  $name = 'Math::PlanePath::QuadricCurve'; $radix=8; # 2*A063481, A013730=2^(3n+1), 2*A059409, A013730=2^(3n+1)
  $name = 'Math::PlanePath::WunderlichSerpentine,serpentine_type=coil'; $radix=3; # none
  $name = 'Math::PlanePath::SierpinskiCurve'; $radix=4; # A079319,A007581,A002450,A006095=(2^n-1)*(2^(n-1) -1)/3,A203241,A006095,A002450,A076024=(2^n+4)*(2^n-1)/6
  $name = 'Math::PlanePath::SierpinskiCurveStair'; $radix=4; # A093069=Kynea,A099393,A060867,A020515
  $name = 'Math::PlanePath::SierpinskiArrowheadCentres'; $radix=3; # West=A094555
  $name = 'Math::PlanePath::SierpinskiArrowhead'; $radix=3; # West=A094555
  $name = 'Math::PlanePath::FibonacciWordFractal'; $radix=2;
  $name = 'Math::PlanePath::AlternatePaperMidpoint'; #   2*A005418 cf fxtbook, A052957=2*A051437altN, A233411, A014236
  $name = 'Math::PlanePath::DekkingCurve'; $radix=25;  # North=South, West=A060870=Cinco.West=sum 5^i
  $name = 'Math::PlanePath::HilbertSpiral'; $radix=2;
  $name = 'Math::PlanePath::HilbertCurve'; $radix=4; # A083885, diff 4^k A123641
  $name = 'Math::PlanePath::TerdragonCurve'; $radix=3; # A092236, A135254, A133474
  $name = 'Math::PlanePath::R5DragonCurve'; $radix=5; # none

  require Math::NumSeq::PlanePathCoord;
  my $path = Math::NumSeq::PlanePathCoord::_planepath_name_to_object($name);
  my %count;
  my %count_arrays;
  my $n = 0;
  my @dxdy_strs = List::Pairwise::mapp {"$a,$b"} $path->_UNDOCUMENTED__dxdy_list;
  require Math::NumSeq::Fibonacci;
  require Math::NumSeq::Fibbinary;
  my $fib = Math::NumSeq::Fibonacci->new;
  my $fibbinary = Math::NumSeq::Fibbinary->new;
  foreach my $k (0 .. 10) {
    my $n_end = $radix**$k;
    # $n_end = $k;
    # $n_end = $fib->ith(2*$k);
    last if $n_end > 500_000;
    for ( ; $n < $n_end; $n++) {
      my ($dx,$dy) = $path->n_to_dxdy($n);
      $count{"$dx,$dy"}++;
    }
    printf "k=%2d ", $k;
    foreach my $dxdy (@dxdy_strs) {
      my $a = $count{$dxdy} || 0;
      my $aref = ($count_arrays{$dxdy} ||= []);
      # push @$aref, $a - $radix**($k-1);  # diff from radix^k
      push @$aref, $a;

      # $a = $fibbinary->ith($a);
      my $ar = Math::BaseCnv::cnv($a,10,$radix);
      printf " %18s", $ar;
    }
    print "\n";
  }
  my $trim = 1;
  foreach my $dxdy (@dxdy_strs) {
    my $aref = $count_arrays{$dxdy} || [];
    splice @$aref, 0, $trim;
    # @$aref = MyOEIS::first_differences(@$aref);
    print "$dxdy\n";
    print "is ", join(',',@$aref),"\n";
    Math::OEIS::Grep->search(array => \@$aref, name => $dxdy);
  }

  # print "\n";
  # foreach my $k (0 .. $#a) {
  #   my $h = int($k/2);
  #   printf "%3d,", $d[$k];
  # }
  # print "\n";
  exit 0;
}
{
  # boundary and area, variations convex hull, minrectangle, etc

  # Terdragon convex hull 14 points
  # Dragon convex hull 10 points, arms=4 12 points

  require Math::Geometry::Planar;
  require Math::NumSeq::PlanePathCoord;
  foreach my $elem (
                    # curves with overlaps only
                    ['TerdragonCurve', 3, 'triangular'],
                    ['TerdragonCurve,arms=6', 3, 'triangular'],
                    ['CCurve', 2],
                    ['DragonCurve', 2],
                    ['DragonCurve,arms=3', 2],
                    ['DragonCurve,arms=2', 2],
                    ['R5DragonCurve', 5],
                    ['DragonCurve,arms=4', 2],
                    ['AlternatePaper', 2],
                    ['AlternatePaper', 4],
                   ) {
    my ($name, $radix, $lattice_type) = @$elem;
    $lattice_type ||= 'square';

    print "$name\n";
    my $path = Math::NumSeq::PlanePathCoord::_planepath_name_to_object($name);
    my $n_start = $path->n_start;
    my $arms = $path->arms_count;

    foreach my $inc_type ('powers',
                          '1',
                         ) {
      foreach my $diffs ('', 'diffs') {
        foreach my $convex_type (
                                 # 'bbox',
                                 'minrectangle',
                                 # 'convex',
                                 # 'full',
                                 # ($inc_type eq 'powers'
                                 #  ? ('left','right')
                                 #  : ()),
                                ) {
          my @areas;
          my @boundaries;
          for (my $level = ($inc_type eq 'powers' ? 0 : 3);
               ;
               $level++) {

            my $n_limit;
            if ($inc_type eq 'powers') {
              unless ((undef, $n_limit) = $path->level_to_n_range($level)) {
                print "no levels for ",ref $path,"\n";
                next;
              }
            } else {
              $n_limit = $n_start + $level;
            }
            last if $n_limit > 20_000;
            last if @areas > 25;

            my $side = ($convex_type eq 'right' ? 'right'
                        : $convex_type eq 'left' ? 'left'
                        : 0);
            print "n_limit=$n_limit  side=$side\n";
            my $points = MyOEIS::path_boundary_points ($path, $n_limit,
                                                       lattice_type => $lattice_type,
                                                       side => $side);
            ### $n_limit
            ### $points

            my $area;
            my $convex_area;
            my $boundary;
            if (@$points <= 1) {
              $area = 0;
              $boundary = 0;
            } elsif (@$points == 2) {
              $area = 0;
              my $dx = $points->[0]->[0] - $points->[1]->[0];
              my $dy = $points->[0]->[1] - $points->[1]->[1];
              my $h = $dx*$dx + $dy*$dy*($lattice_type eq 'triangular' ? 3 : 0);
              $boundary = 2*sqrt($h);
            } else {
              my $polygon = Math::Geometry::Planar->new;
              $polygon->points($points);

              if (($convex_type eq 'convex'
                   || $convex_type eq 'minrectangle')
                  && @$points >= 5) {
                $polygon = $polygon->convexhull2;
                $points = $polygon->points;
              }
              if ($convex_type eq 'bbox') {
                $polygon = $polygon->bbox;
                $points = $polygon->points;
              }
              if ($convex_type eq 'minrectangle') {
                if (@$points <= 16) {
                  print "   ",points_str($points),"\n";
                }
                $polygon = $polygon->minrectangle;
                $points = $polygon->points;
              }

              $area = $polygon->area;

              if ($lattice_type eq 'triangular') {
                foreach my $p (@$points) {
                  $p->[1] *= sqrt(3);
                  # $p->[0] *= 1/2;
                  # $p->[1] *= sqrt(3)/2;
                }
                $polygon->points($points);
              }
              $boundary = $polygon->perimeter;
            }

            if ($convex_type eq 'right' || $convex_type eq 'left') {
              $boundary = scalar(@$points) - 1;
              # my ($end_x,$end_y) = $path->n_to_xy($n_limit);
              # $boundary -= hypot($end_x,$end_y);
              # $boundary = float_error($boundary);
            }
            push @areas, $area;
            push @boundaries, $boundary;

            my $notint = ($boundary == int($boundary) ? '' : ' (not int)');
            my $num_points = scalar(@$points);
            print "$level $n_limit points=$num_points area=$area boundary=$boundary$notint $convex_type\n";
            if (@$points <= 10) {
              print "   ",points_str($points),"\n";
            }

            if (0) {
              require Image::Base::GD;
              my $width = 800;
              my $height = 700;
              my $image = Image::Base::GD->new (-width => $width, -height => $height);
              $image->rectangle (0,0, $width-1,$height-1, 'black');
              my $x_max = 0;
              my $x_min = 0;
              my $y_max = 0;
              my $y_min = 0;
              foreach my $p (@$points) {
                my ($x,$y) = @$p;
                $x_max = max($x_max, $x);
                $y_max = max($y_max, $y);
                $x_min = min($x_min, $x);
                $y_min = min($y_min, $y);
              }
              my $x_size = $x_max - $x_min;
              my $y_size = $y_max - $y_min;
              $x_size *= 1.1;
              $y_size *= 1.1;
              my $x_scale = $width / $x_size;
              my $y_scale = $height / ($y_size || 1);
              my $scale = min($x_scale,$y_scale);
              my $x_mid = ($x_min + $x_max) / 2;
              my $y_mid = ($y_min + $y_max) / 2;
              my $convert = sub {
                my ($x,$y) = @_;
                $x -= $x_mid;   $y -= $y_mid;
                $x *= $scale;   $y *= $scale;
                $x += $width/2; $y = $height/2 - $y;
                return ($x,$y);
              };
              {
                my ($x,$y) = $convert->(0,0);
                $image->ellipse ($x-3,$y-3, $x+3,$y+3, 'white', 1);
              }
              foreach my $i (0 .. $#$points) {
                my ($x1,$y1) = @{$points->[$i-1]};
                my ($x2,$y2) = @{$points->[$i]};
                ($x1,$y1) = $convert->($x1,$y1);
                ($x2,$y2) = $convert->($x2,$y2);
                $image->line ($x1,$y1, $x2,$y2, 'white');
              }
              $image->save('/tmp/x.png');
              require IPC::Run;
              IPC::Run::run (['xzgv','/tmp/x.png']);
            }
          }

          if ($diffs) {
            foreach my $i (reverse 1 .. $#areas) {
              $areas[$i] -= $areas[$i-1];
            }
            foreach my $i (reverse 1 .. $#boundaries) {
              $boundaries[$i] -= $boundaries[$i-1];
            }
            shift @areas;
            shift @boundaries;
          }

          foreach my $alt_type (# 'even','odd',
                                'all') {
            my @areas = @areas;
            my @boundaries = @boundaries;

            if ($alt_type eq 'odd') {
              aref_keep_odds(\@areas);
              aref_keep_odds(\@boundaries);
            }
            if ($alt_type eq 'even') {
              aref_keep_evens(\@areas);
              aref_keep_evens(\@boundaries);
            }

            print "\n$name area (by $inc_type $convex_type $diffs $alt_type):\n";
            shift_off_zeros(\@areas);
            print join(',',@areas),"\n";
            Math::OEIS::Grep->search(array => \@areas);

            print "\n$name boundary (by $inc_type $convex_type $diffs $alt_type):\n";
            shift_off_zeros(\@boundaries);
            print join(',',@boundaries),"\n";
            Math::OEIS::Grep->search(array => \@boundaries);
            print "\n";
          }
        }
      }
    }
  }

  exit 0;

  sub points_str {
    my ($points) = @_;
    ### points_str(): $points
    my $count = scalar(@$points);
    return  "count=$count  ".join(' ',map{join(',',@$_)}@$points)
  }

  # shift any leading zeros off @$aref
  sub shift_off_zeros {
    my ($aref) = @_;
    while (@$aref && ! $aref->[0]) {
      shift @$aref;
    }
  }

  sub aref_keep_odds {
    my ($aref) = @_;
    @$aref = map { $_ & 1 ? $aref->[$_] : () } 0 .. $#$aref;
  }
  sub aref_keep_evens {
    my ($aref) = @_;
    @$aref = map { $_ & 1 ? () : $aref->[$_] } 0 .. $#$aref;
  }

  BEGIN {
    my @dir6_to_dx = (2, 1,-1,-2, -1, 1);
    my @dir6_to_dy = (0, 1, 1, 0, -1,-1);

    sub path_boundary_points_triangular {
      my ($path, $n_limit) = @_;
      my @points;
      my $x = 0;
      my $y = 0;
      my $dir6 = 4;
      my @n_list = ($path->n_start);
      for (;;) {
        ### at: "$x, $y  dir6 = $dir6"
        push @points, [$x,$y];
        $dir6 -= 2;  # rotate -120
        foreach (1 .. 6) {
          $dir6 %= 6;
          my $dx = $dir6_to_dx[$dir6];
          my $dy = $dir6_to_dy[$dir6];
          my @next_n_list = $path->xy_to_n_list($x+$dx,$y+$dy);
          ### @next_n_list
          if (any_consecutive(\@n_list, \@next_n_list, $n_limit)) {
            @n_list = @next_n_list;
            $x += $dx;
            $y += $dy;
            last;
          }
          $dir6++;  # +60
        }
        if ($x == 0 && $y == 0) {
          last;
        }
      }
      return \@points;
    }
  }
}

{
  # N where two paths have same X,Y

  # path1 RationalsTree tree_type,SB
  # path2 RationalsTree tree_type,Drib
  # path1 RationalsTree tree_type,CW
  # path2 RationalsTree tree_type,Bird
  # values: 3,34,38,40,44,51,55,57,61,522,538,546,562,590,606,614,630,648,664,672,688,716,732,740,756,779,795,803,819,847

  # path1 RationalsTree tree_type,SB
  # path2 RationalsTree tree_type,AYT
  # path1 RationalsTree tree_type,AYT
  # path2 RationalsTree tree_type,SB
  # values: 6,11,54,91,438,731,3510,5851,28086,46811
  # octal 1333333,6666666,repeating

  # path1 RationalsTree tree_type,CW
  # path2 RationalsTree tree_type,HCS
  # path1 RationalsTree tree_type,HCS
  # path2 RationalsTree tree_type,CW
  # values: 5,14,45,118,365,950,2925,7606,23405,60854
  # octal 166666,55555 repeating

  # path1 RationalsTree tree_type,AYT
  # path2 RationalsTree tree_type,Bird
  # path1 RationalsTree tree_type,Bird
  # path2 RationalsTree tree_type,AYT
  # values: 5,12,41,100,329,804,2633,6436,21065,51492
  # octal 1444444,511111 repeating

  # path1 RationalsTree tree_type,HCS
  # path2 RationalsTree tree_type,Drib
  # path1 RationalsTree tree_type,Drib
  # path2 RationalsTree tree_type,HCS
  # values: 6,9,50,73,402,585,3218,4681,25746,37449
  # octal 1111111,622222 repeating


  require Math::NumSeq::PlanePathCoord;
  my @choices = @{Math::NumSeq::PlanePathCoord->parameter_info_hash
      ->{'planepath'}->{'choices'}};

  @choices = grep {$_ ne 'CellularRule'} @choices;
  @choices = grep {$_ ne 'Rows'} @choices;
  @choices = grep {$_ ne 'Columns'} @choices;
  @choices = grep {$_ ne 'ArchimedeanChords'} @choices;
  @choices = grep {$_ ne 'MultipleRings'} @choices;
  @choices = grep {$_ ne 'VogelFloret'} @choices;
  @choices = grep {$_ ne 'PythagoreanTree'} @choices;
  @choices = grep {$_ ne 'PeanoHalf'} @choices;
  @choices = grep {$_ !~ /EToothpick|LToothpick|Surround|Peninsula/} @choices;
  @choices = grep {$_ ne 'CornerReplicate'} @choices;
  @choices = grep {$_ ne 'ZOrderCurve'} @choices;
  unshift @choices, 'CornerReplicate', 'ZOrderCurve';

  @choices = ('RationalsTree');

  my $num_choices = scalar(@choices);
  print "$num_choices choices\n";

  my @path_objects;
  my %path_fullnames;
  foreach my $name (@choices) {
    my $class = "Math::PlanePath::$name";
    Module::Load::load($class);

    my $parameters = parameter_info_list_to_parameters
      ($class->parameter_info_list);
    foreach my $p (@$parameters) {
      my $path_object = $class->new (@$p);
      push @path_objects, $path_object;
      $path_fullnames{$path_object} = "$name ".join(',',@$p);
    }
  }
  my $num_path_objects = scalar(@path_objects);
  print "total path objects $num_path_objects\n";

  my $start_t = time();
  my $t = $start_t-8;

  my $i = 0;
  # until ($path_objects[$i]->isa('Math::PlanePath::DiamondArms')) {
  #   $i++;
  # }
  # while ($path_objects[$i]->isa('Math::PlanePath::PyramidSpiral')) {
  #   $i++;
  # }

  my $start_permutations = $i * ($num_path_objects-1);
  my $num_permutations = $num_path_objects * ($num_path_objects-1);

  open DEBUG, '>/tmp/permutations.out' or die;
  select DEBUG or die; $| = 1; # autoflush
  select STDOUT or die;

  for ( ; $i <= $#path_objects; $i++) {
    my $from_path = $path_objects[$i];
    my $from_fullname = $path_fullnames{$from_path};
    my $n_start = $from_path->n_start;

  PATH: foreach my $j (0 .. $#path_objects) {
      if (time()-$t < 0 || time()-$t > 10) {
        my $upto_permutation = $i*$num_path_objects + $j || 1;
        my $rem_permutation = $num_permutations
          - ($start_permutations + $upto_permutation);
        my $done_permutations = ($upto_permutation-$start_permutations);
        my $percent = 100 * $done_permutations / $num_permutations || 1;
        my $t_each = (time() - $start_t) / $done_permutations;
        my $done_per_second = $done_permutations / (time() - $start_t);
        my $eta = int($t_each * $rem_permutation);
        my $s = $eta % 60; $eta = int($eta/60);
        my $m = $eta % 60; $eta = int($eta/60);
        my $h = $eta;
        my $eta_str = sprintf '%d:%02d:%02d', $h,$m,$s;
        print "$upto_permutation / $num_permutations  est $eta_str  (each $t_each)\n";
        $t = time();
      }

      next if $i == $j;
      my $to_path = $path_objects[$j];
      next if $to_path->n_start != $n_start;
      my $to_fullname = $path_fullnames{$to_path};
      my $name = ("path1 $from_fullname\n"
                  . "path2 $to_fullname\n");

      print DEBUG "$name\n";

      my $str = '';
      my @values;
      my $gap = 0;

      for (my $n = $n_start+2; @values < 30 && $gap < 100_000; $n++) {
        my ($x1,$y1) = $from_path->n_to_xy($n)
          or next PATH;
        my ($x2,$y2) = $to_path->n_to_xy($n)
          or next PATH;
        if ($x1 == $x2 && $y1 == $y2) {
          push @values, $n;
          $gap = 0;
        } else {
          $gap++;
        }
      }
      if (@values < 5) {
        print DEBUG "only ",scalar(@values)," values: ",join(',',@values),"\n";
        next;
      }

      print DEBUG "values: ",join(',',@values),"\n";
      Math::OEIS::Grep->search(name => $name,
                               array => \@values);
      print DEBUG "\n\n";
    }
  }
  exit 0;
}
{
  # permutation between two paths

  require Math::NumSeq::PlanePathCoord;
  my @choices = @{Math::NumSeq::PlanePathCoord->parameter_info_hash
      ->{'planepath'}->{'choices'}};

  @choices = grep {$_ ne 'CellularRule'} @choices;
  @choices = grep {$_ ne 'Rows'} @choices;
  @choices = grep {$_ ne 'Columns'} @choices;
  @choices = grep {$_ ne 'ArchimedeanChords'} @choices;
  @choices = grep {$_ ne 'MultipleRings'} @choices;
  @choices = grep {$_ ne 'VogelFloret'} @choices;
  @choices = grep {$_ ne 'PythagoreanTree'} @choices;
  @choices = grep {$_ ne 'PeanoHalf'} @choices;
  @choices = grep {$_ !~ /EToothpick|LToothpick|Surround|Peninsula/} @choices;

  @choices = grep {$_ ne 'CornerReplicate'} @choices;
  @choices = grep {$_ ne 'ZOrderCurve'} @choices;
  unshift @choices, 'CornerReplicate', 'ZOrderCurve';

  @choices = ('PythagoreanTree');

  my $num_choices = scalar(@choices);
  print "$num_choices choices\n";

  my @path_objects;
  my %path_fullnames;
  foreach my $name (@choices) {
    my $class = "Math::PlanePath::$name";
    Module::Load::load($class);

    my $parameters = parameter_info_list_to_parameters
      ($class->parameter_info_list);
    foreach my $p (@$parameters) {
      my $path_object = $class->new (@$p);
      push @path_objects, $path_object;
      $path_fullnames{$path_object} = "$name ".join(',',@$p);
    }
  }
  my $num_path_objects = scalar(@path_objects);
  print "total path objects $num_path_objects\n";

  my $start_t = time();
  my $t = $start_t-8;

  my $i = 0;
  # until ($path_objects[$i]->isa('Math::PlanePath::DiamondArms')) {
  #   $i++;
  # }
  # while ($path_objects[$i]->isa('Math::PlanePath::PyramidSpiral')) {
  #   $i++;
  # }

  my $start_permutations = $i * ($num_path_objects-1);
  my $num_permutations = $num_path_objects * ($num_path_objects-1);

  open DEBUG, '>/tmp/permutations.out' or die;
  select DEBUG or die; $| = 1; # autoflush
  select STDOUT or die;

  for ( ; $i <= $#path_objects; $i++) {
    my $from_path = $path_objects[$i];
    my $from_fullname = $path_fullnames{$from_path};
    my $n_start = $from_path->n_start;

  PATH: foreach my $j (0 .. $#path_objects) {
      if (time()-$t < 0 || time()-$t > 10) {
        my $upto_permutation = $i*$num_path_objects + $j || 1;
        my $rem_permutation = $num_permutations
          - ($start_permutations + $upto_permutation);
        my $done_permutations = ($upto_permutation-$start_permutations);
        my $percent = 100 * $done_permutations / $num_permutations || 1;
        my $t_each = (time() - $start_t) / $done_permutations;
        my $done_per_second = $done_permutations / (time() - $start_t);
        my $eta = int($t_each * $rem_permutation);
        my $s = $eta % 60; $eta = int($eta/60);
        my $m = $eta % 60; $eta = int($eta/60);
        my $h = $eta;
        my $eta_str = sprintf '%d:%02d:%02d', $h,$m,$s;
        print "$upto_permutation / $num_permutations  est $eta_str  (each $t_each)\n";
        $t = time();
      }

      next if $i == $j;
      my $to_path = $path_objects[$j];
      next if $to_path->n_start != $n_start;
      my $to_fullname = $path_fullnames{$to_path};
      my $name = "$from_fullname -> $to_fullname";

      print DEBUG "$name\n";

      my $str = '';
      my @values;
      foreach my $n ($n_start+2 .. $n_start+50) {
        my ($x,$y) = $from_path->n_to_xy($n)
          or next PATH;
        my $pn = $to_path->xy_to_n($x,$y) // next PATH;
        $str .= "$pn,";
        push @values, $pn;
      }
      Math::OEIS::Grep->search(name => $name,
                                    array => \@values);
    }
  }
  exit 0;
}

{
  # cross-product of successive dx,dy, being turn discriminant

  require Math::NumSeq::PlanePathCoord;
  my @choices = @{Math::NumSeq::PlanePathCoord->parameter_info_hash
      ->{'planepath'}->{'choices'}};
  @choices = grep {$_ ne 'CellularRule'} @choices;

  my $num_choices = scalar(@choices);
  print "$num_choices choices\n";

  my @path_objects;
  my %path_fullnames;
  foreach my $name (@choices) {
    my $class = "Math::PlanePath::$name";
    Module::Load::load($class);

    my $parameters = parameter_info_list_to_parameters
      ($class->parameter_info_list);
    foreach my $p (@$parameters) {
      my $path_object = $class->new (@$p);
      push @path_objects, $path_object;
      $path_fullnames{$path_object} = "$name ".join(',',@$p);
    }
  }
  my $num_path_objects = scalar(@path_objects);
  print "total path objects $num_path_objects\n";

  my %seen;
  foreach my $path (@path_objects) {
    my $fullname = $path_fullnames{$path};
    print "$fullname\n";

    my $n = $path->n_start + 2;
    my ($prev_dx,$prev_dy) = $path->n_to_dxdy($n)
      or next;
    my @values;
    for ($n++; @values < 30; $n++) {
      my ($dx,$dy) = $path->n_to_dxdy($n)
        or last;
      push @values, $dx * $prev_dy - $prev_dx * $dy;

    }

    print join(',', @values),"\n";
    Math::OEIS::Grep->search(array => \@values,
                                  try_abs => 0);
  }
  exit 0;
}

{
  # boundary length by N, unit squares

  require Math::NumSeq::PlanePathCoord;
  my @choices = @{Math::NumSeq::PlanePathCoord->parameter_info_hash
      ->{'planepath'}->{'choices'}};
  @choices = grep {$_ ne 'CellularRule'} @choices;
  @choices = grep {$_ ne 'ArchimedeanChords'} @choices;
  @choices = grep {$_ ne 'TheodorusSpiral'} @choices;
  @choices = grep {$_ ne 'MultipleRings'} @choices;
  @choices = grep {$_ ne 'VogelFloret'} @choices;
  @choices = grep {$_ ne 'UlamWarburtonAway'} @choices;
  @choices = grep {$_ !~ /Hypot|ByCells|SumFractions|WythoffTriangle/} @choices;
  @choices = grep {$_ ne 'PythagoreanTree'} @choices;
  # @choices = grep {$_ ne 'PeanoHalf'} @choices;
  @choices = grep {$_ !~ /EToothpick|LToothpick|Surround|Peninsula/} @choices;
  #
  # @choices = grep {$_ eq 'WythoffArray'} @choices;
  # @choices = grep {$_ ne 'ZOrderCurve'} @choices;
  # unshift @choices, 'CornerReplicate', 'ZOrderCurve';

  my $num_choices = scalar(@choices);
  print "$num_choices choices\n";

  @choices = ((grep {/Corner|Tri/} @choices),
              (grep {!/Corner|Tri/} @choices));

  my @path_objects;
  my %path_fullnames;
  foreach my $name (@choices) {
    my $class = "Math::PlanePath::$name";
    ### $class
    Module::Load::load($class);

    my $parameters = parameter_info_list_to_parameters
      ($class->parameter_info_list);
    foreach my $p (@$parameters) {
      my $path_object = $class->new (@$p);
      push @path_objects, $path_object;
      $path_fullnames{$path_object} = "$name ".join(',',@$p);
    }
  }
  my $num_path_objects = scalar(@path_objects);
  print "total path objects $num_path_objects\n";

  my $start_t = time();
  my $t = $start_t-8;

  my $i = 0;
  # until ($path_objects[$i]->isa('Math::PlanePath::DragonCurve')) {
  #   $i++;
  # }
  my $start_permutations = $i * ($num_path_objects-1);
  my $num_permutations = $num_path_objects * ($num_path_objects-1);

  for ( ; $i <= $#path_objects; $i++) {
    my $path = $path_objects[$i];
    my $fullname = $path_fullnames{$path};
    print "$fullname\n";

    my $x_minimum = $path->x_minimum;
    my $y_minimum = $path->y_minimum;

    my @values;
    my $boundary = 0;
    foreach my $n ($path->n_start .. 30) {
      $boundary += path_n_to_dboundary($path,$n);
      # $boundary += path_n_to_dsticks($path,$n);
      # $boundary += path_n_to_dhexboundary($path,$n);
      # $boundary += path_n_to_dhexsticks($path,$n);

      my $value = $boundary;
      push @values, $value;
    }
    shift @values;
    print join(',',@values),"\n";
    Math::OEIS::Grep->search(array => \@values);
    print "\n";
  }
  exit 0;
}
{
  # boundary of unit squares by powers

  require Math::NumSeq::PlanePathCoord;
  foreach my $elem (
                    # ['WythoffArray', 'zeck'],

                    ['ComplexPlus', 1*1+1],
                    ['ComplexPlus,realpart=2', 2*2+1],
                    ['ComplexPlus,realpart=3', 3*3+1],
                    ['ComplexMinus', 1*1+1],
                    ['ComplexMinus,realpart=2', 2*2+1],
                    ['ComplexMinus,realpart=3', 3*3+1],

                    ['CCurve', 2],
                    ['GosperReplicate',7, 'triangular'],
                    ['Flowsnake',7, 'triangular'],
                    ['FlowsnakeCentres',7, 'triangular'],

                    ['PowerArray',2],
                    ['PowerArray,radix=3',3],

                    ['CubicBase',2, 'triangular'],
                    ['CubicBase,radix=3',3, 'triangular'],
                    ['TerdragonCurve', 3, 'triangular'],
                    ['TerdragonMidpoint', 3, 'triangular'],

                    ['QuintetCentres',5],
                    ['QuintetCurve',5],

                    ['AlternatePaperMidpoint', 2],
                    ['R5DragonCurve', 5],
                    ['DragonMidpoint', 2],

                    ['AlternatePaper', 2],
                    ['DragonCurve', 2],
                   ) {
    my ($name, $radix, $lattice_type) = @$elem;
    $lattice_type ||= 'square';

    print "$name  (lattice=$lattice_type)\n";
    my $path = Math::NumSeq::PlanePathCoord::_planepath_name_to_object($name);
    my $n_start = $path->n_start;

    my @boundaries;
    my $n = $n_start;
    my $boundary = 0;
    my $target = $radix;
    my $dboundary_func = ($lattice_type eq 'triangular'
                          ? \&path_n_to_dhexboundary
                          : \&path_n_to_dboundary);
    for (;; $n++) {
      ### at: "boundary=$boundary  now consider N=$n"
      last if @boundaries > 20;
      if ($n > $target) {
        print "$target  $boundary\n";
        push @boundaries, $boundary;
        $target *= $radix;
        last if $target > 10_000;
      }
      $boundary += $dboundary_func->($path,$n);
    }

    print "$name unit squares boundary\n";
    shift_off_zeros(\@boundaries);
    print join(',',@boundaries),"\n";
    Math::OEIS::Grep->search(array => \@boundaries);
    print "\n";
  }

  exit 0;
}

{
  # permutation of transpose
  require Math::NumSeq::PlanePathCoord;
  my @choices = @{Math::NumSeq::PlanePathCoord->parameter_info_hash
      ->{'planepath'}->{'choices'}};
  @choices = grep {$_ ne 'BinaryTerms'} @choices; # bit slow yet
  my %seen;
  foreach my $path_name (@choices) {
    my $path_class = "Math::PlanePath::$path_name";
    Module::Load::load($path_class);
    my $parameters = parameter_info_list_to_parameters($path_class->parameter_info_list);
  PATH: foreach my $p (@$parameters) {
      my $name = "$path_name  ".join(',',@$p);
      my $path = $path_class->new (@$p);
      my @values;
      foreach my $n ($path->n_start+1 .. 35) {
        # my $value = (defined $path->tree_n_to_subheight($n) ? 1 : 0);

        my ($x,$y) = $path->n_to_xy($n) or next PATH;
        # # my $value = $path->xy_to_n($y,$x);  # transpose
        # my $value = $path->xy_to_n(-$x,$y);   # horiz mirror
        # my $value = $path->xy_to_n($x,-$y);   # vert mirror

        # ($x,$y) = ($y,-$x);  # rotate -90
        # ($x,$y) = ($y,$x);   # transpose
        # ($x,$y) = (-$y,$x);  # rotate +90
        my $value = $path->xy_to_n(-$y,-$x);   # mirror across opp diagonal

        next PATH if ! defined $value;
        push @values, $value;
      }
      Math::OEIS::Grep->search(name => $name,
                               array => \@values);
    }
  }
  exit 0;
}

{
  # tree row totals

  require Math::NumSeq::PlanePathCoord;
  my @choices = @{Math::NumSeq::PlanePathCoord->parameter_info_hash
      ->{'planepath'}->{'choices'}};
  @choices = grep {$_ ne 'CellularRule'} @choices;
  @choices = grep {$_ ne 'UlamWarburtonAway'} @choices; # not working yet
  @choices = grep {$_ !~ /EToothpick|LToothpick|Surround|Peninsula/} @choices;

  my $num_choices = scalar(@choices);
  print "$num_choices choices\n";

  my @path_objects;
  my %path_fullnames;
  foreach my $name (@choices) {
    my $class = "Math::PlanePath::$name";
    ### $class
    Module::Load::load($class);

    my $parameters = parameter_info_list_to_parameters
      ($class->parameter_info_list);
    foreach my $p (@$parameters) {
      my $path_object = $class->new (@$p);
      push @path_objects, $path_object;
      $path_fullnames{$path_object} = "$name ".join(',',@$p);
    }
  }
  my $num_path_objects = scalar(@path_objects);
  print "total path objects $num_path_objects\n";

  my $start_t = time();
  my $t = $start_t-8;

  my $i = 0;
  # until ($path_objects[$i]->isa('Math::PlanePath::DragonCurve')) {
  #   $i++;
  # }

  for ( ; $i <= $#path_objects; $i++) {
    my $path = $path_objects[$i];
    next unless $path->x_negative || $path->y_negative;
    $path->is_tree($path) or next;

    my $fullname = $path_fullnames{$path};
    print "$fullname  (",ref $path,")\n";

    my @x_total;
    my @y_total;
    my @sum_total;
    my @diff_total;
    my $target_depth = 0;
    my $target = $path->tree_depth_to_n_end($target_depth);
    for (my $n = $path->n_start; $n < 10_000; $n++) {
      my ($x,$y) = $path->n_to_xy($n);
      my $depth = $path->tree_n_to_depth($n);
      $x = abs($x);
      $y = abs($y);
      $x_total[$depth] += $x;
      $y_total[$depth] += $y;
      $sum_total[$depth] += $x + $y;
      $diff_total[$depth] += $x - $y;

      if ($n == $target) {
        print "$target_depth   $x_total[$target_depth] $y_total[$target_depth]\n";
        $target_depth++;
        last if $target_depth > 12;
        $target = $path->tree_depth_to_n_end($target_depth);
      }
    }
    $#x_total = $target_depth-1;
    $#y_total = $target_depth-1;
    $#sum_total = $target_depth-1;
    $#diff_total = $target_depth-1;

    print "X rows\n";
    Math::OEIS::Grep->search(array => \@x_total);
    print "\n";

    print "Y rows\n";
    Math::OEIS::Grep->search(array => \@y_total);
    print "\n";

    print "X+Y rows\n";
    Math::OEIS::Grep->search(array => \@sum_total);
    print "\n";

    print "X-Y rows\n";
    Math::OEIS::Grep->search(array => \@diff_total);
    print "\n";
  }
  exit 0;
}


BEGIN {
  my @dir6_to_dx = (2, 1,-1,-2, -1, 1);
  my @dir6_to_dy = (0, 1, 1, 0, -1,-1);

  # Return the change in boundary length when hexagon $n is added.
  # This is +6 if it's completely isolated, and 2 less for each neighbour
  # < $n since 1 side of the neighbour and 1 side of $n are then not
  # boundaries.
  #
  sub path_n_to_dhexboundary {
    my ($path, $n) = @_;
    my ($x,$y) = $path->n_to_xy($n) or return 0;
    my $dboundary = 6;
    foreach my $i (0 .. $#dir6_to_dx) {
      my $an = $path->xy_to_n($x+$dir6_to_dx[$i], $y+$dir6_to_dy[$i]);
      $dboundary -= 2*(defined $an && $an < $n);
    }
    ### $dboundary
    return $dboundary;
  }
  sub path_n_to_dhexsticks {
    my ($path, $n) = @_;
    my ($x,$y) = $path->n_to_xy($n) or return 0;
    my $dboundary = 6;
    foreach my $i (0 .. $#dir6_to_dx) {
      my $an = $path->xy_to_n($x+$dir6_to_dx[$i], $y+$dir6_to_dy[$i]);
      $dboundary -= (defined $an && $an < $n);
    }
    return $dboundary;
  }
}

{
  # path classes with or without n_start
  require Math::NumSeq::PlanePathCoord;
  my @choices = @{Math::NumSeq::PlanePathCoord->parameter_info_hash
      ->{'planepath'}->{'choices'}};

  my (@with, @without);
  foreach my $name (@choices) {
    my $class = "Math::PlanePath::$name";
    Module::Load::load($class);
    my $href = $class->parameter_info_hash;
    if ($href->{'n_start'}) {
      push @with, $class;
    } else {
      push @without, $class;
    }
  }
  foreach my $aref (\@without, \@with) {
    foreach my $class (@$aref) {
      my @pnames = map {$_->{'name'}} $class->parameter_info_list;
      my $href = $class->parameter_info_hash;
      my $w = ($href->{'n_start'} ? 'with' : 'without');
      print "  $class [$w] ",join(',',@pnames),"\n";
      # print "    ",join(', ',keys %$href),"\n";
    }
    print "\n\n";
  }
  exit 0;
}

{
  require Math::PlanePath::DragonCurve;
  my $path = Math::PlanePath::DragonCurve->new;
  my @values;
  foreach my $n (3 .. 32) {
    my ($x,$y) = $path->n_to_xy(2*$n);
    # push @values,-$x-1;
    my $transitions = transitions($n);
    push @values, (($transitions%4)/2);
    # push @values, $transitions;
  }
  my $values = join(',',@values);
  print "$values\n";
  Math::OEIS::Grep->search(array=>\@values);
  exit 0;

  # transitions(2n)/2 = A069010 Number of runs of 1's
  sub transitions {
    my ($n) = @_;
    my $count = 0;
    while ($n) {
      $count += (($n & 3) == 1 || ($n & 3) == 2);
      $n >>= 1;
    }
    return $count
  }
}

{
  # tree row increments
  require Math::NumSeq::PlanePathCoord;
  my @choices = @{Math::NumSeq::PlanePathCoord->parameter_info_hash
      ->{'planepath'}->{'choices'}};

  # @choices = grep {$_ ne 'CellularRule'} @choices;
  # @choices = grep {$_ ne 'Rows'} @choices;
  # @choices = grep {$_ ne 'Columns'} @choices;
  # @choices = grep {$_ ne 'ArchimedeanChords'} @choices;
  @choices = grep {$_ ne 'MultipleRings'} @choices;
  @choices = grep {$_ ne 'VogelFloret'} @choices;
  @choices = grep {$_ !~ /ByCells/} @choices;
  # @choices = grep {$_ ne 'PythagoreanTree'} @choices;
  # @choices = grep {$_ ne 'PeanoHalf'} @choices;
  # @choices = grep {$_ !~ /EToothpick|LToothpick|Surround|Peninsula/} @choices;
  #
  # @choices = grep {$_ ne 'CornerReplicate'} @choices;
  # @choices = grep {$_ ne 'ZOrderCurve'} @choices;
  # unshift @choices, 'CornerReplicate', 'ZOrderCurve';

  my $num_choices = scalar(@choices);
  print "$num_choices choices\n";

  my @path_objects;
  my %path_fullnames;
  foreach my $name (@choices) {
    my $class = "Math::PlanePath::$name";
    ### $class
    Module::Load::load($class);

    my $parameters = parameter_info_list_to_parameters
      ($class->parameter_info_list);
    foreach my $p (@$parameters) {
      my $path_object = $class->new (@$p);
      push @path_objects, $path_object;
      $path_fullnames{$path_object} = "$name ".join(',',@$p);
    }
  }
  my $num_path_objects = scalar(@path_objects);
  print "total path objects $num_path_objects\n";

  my $start_t = time();
  my $t = $start_t-8;

  my $i = 0;
  # until ($path_objects[$i]->isa('Math::PlanePath::DiamondArms')) {
  #   $i++;
  # }

  my $start_permutations = $i * ($num_path_objects-1);
  my $num_permutations = $num_path_objects * ($num_path_objects-1);

  for ( ; $i <= $#path_objects; $i++) {
    my $path = $path_objects[$i];
    my $fullname = $path_fullnames{$path};
    my $n_start = $path->n_start;
    $path->is_tree($path) or next;
    print "$fullname\n";

    # if (time()-$t < 0 || time()-$t > 10) {
    #   my $upto_permutation = $i*$num_path_objects + $j || 1;
    #   my $rem_permutation = $num_permutations
    #     - ($start_permutations + $upto_permutation);
    #   my $done_permutations = ($upto_permutation-$start_permutations);
    #   my $percent = 100 * $done_permutations / $num_permutations || 1;
    #   my $t_each = (time() - $start_t) / $done_permutations;
    #   my $done_per_second = $done_permutations / (time() - $start_t);
    #   my $eta = int($t_each * $rem_permutation);
    #   my $s = $eta % 60; $eta = int($eta/60);
    #   my $m = $eta % 60; $eta = int($eta/60);
    #   my $h = $eta;
    #   print "$upto_permutation / $num_permutations  est $h:$m:$s  (each $t_each)\n";
    #   $t = time();
    # }

    my $str = '';
    my @values;
    foreach my $depth (1 .. 50) {
      # my $value = $path->tree_depth_to_width($depth) // next;
      my $value = $path->tree_depth_to_n($depth) % 2;
      $str .= "$value,";
      push @values, $value;
    }
    if (defined (my $diff = constant_diff(@values))) {
      print "$fullname\n";
      print "  constant diff $diff\n";
      next;
    }
    if (my $found = stripped_grep($str)) {
      print "$fullname  match\n";
      print "  (",substr($str,0,60),"...)\n";
      print $found;
      print "\n";
    }
  }
  exit 0;

}

{
  # X,Y extents

  require Math::NumSeq::PlanePathCoord;
  my @choices = @{Math::NumSeq::PlanePathCoord->parameter_info_hash
      ->{'planepath'}->{'choices'}};

  my $num_choices = scalar(@choices);
  print "$num_choices choices\n";

  my @path_objects;
  my %path_fullnames;
  foreach my $name (@choices) {
    my $class = "Math::PlanePath::$name";
    Module::Load::load($class);

    my $parameters = parameter_info_list_to_parameters
      ($class->parameter_info_list);
    foreach my $p (@$parameters) {
      my $path_object = $class->new (@$p);
      push @path_objects, $path_object;
      $path_fullnames{$path_object} = "$name ".join(',',@$p);
    }
  }
  my $num_path_objects = scalar(@path_objects);
  print "total path objects $num_path_objects\n";

  my %seen;
  foreach my $path (@path_objects) {
    print $path_fullnames{$path},"\n";

    my $any_x_neg = 0;
    my $any_y_neg = 0;
    my (@x,@y,@n);
    foreach my $n ($path->n_start+2 .. 50) {
      my ($x,$y) = $path->n_to_xy($n)
        or last;
      push @x, $x;
      push @y, $y;
      push @n, $n;
      $any_x_neg ||= ($x < 0);
      $any_y_neg ||= ($y < 0);
    }
    next unless $any_x_neg || $any_y_neg;

    foreach my $x_axis_pos ($any_y_neg ? -1 : (),
                            0, 1) {

      foreach my $x_axis_neg (($any_y_neg ? (-1) : ()),
                              0,
                              ($any_x_neg ? (1) : ())) {

        foreach my $y_axis_pos ($any_x_neg ? -1 : (),
                                0, 1) {

          foreach my $y_axis_neg ($any_x_neg ? (-1) : (),
                                  0,
                                  ($any_y_neg ? (1) : ())) {

            my $fullname = $path_fullnames{$path} . " Xpos=$x_axis_pos Xneg=$x_axis_neg Ypos=$y_axis_pos Yneg=$y_axis_neg";

            my @values;
            my $str = '';
            foreach my $i (0 .. $#x) {
              if (($x[$i]<=>0) == ($y[$i]<0 ? $y_axis_neg : $y_axis_pos)
                  && ($y[$i]<=>0) == ($x[$i]<0 ? $x_axis_neg : $x_axis_pos)
                 ) {
                push @values, $n[$i];
                $str .= "$n[$i],";
              }
            }
            next unless @values >= 5;

            if (my $prev_fullname = $seen{$str}) {
              print "$fullname\n";
              print "repeat of $prev_fullname";
              print "\n";
            } else {
              if (my $found = stripped_grep($str)) {
                print "$fullname\n";
                print "  (",substr($str,0,20),"...)\n";
                print $found;
                print "\n";
                print "\n";
                $seen{$str} = $fullname;
              }
            }
          }
        }
      }
    }
  }
  exit 0;
}


# sub stripped_grep {
#   my ($str) = @_;
#   my $find = `fgrep -e $str $ENV{HOME}/OEIS/stripped`;
#   my $ret = '';
#   foreach my $line (split /\n/, $find) {
#     $ret .= "$line\n";
#     my ($anum) = ($line =~ /^(A\d+)/) or die;
#     $ret .= `zgrep -e ^$anum $ENV{HOME}/OEIS/names.gz`;
#   }
#   return $ret;
# }

my $stripped;
sub stripped_grep {
  my ($str) = @_;
  if (! $stripped) {
    require File::Map;
    my $filename = "$ENV{HOME}/OEIS/stripped";
    File::Map::map_file ($stripped, $filename);
    print "File::Map file length ",length($stripped),"\n";
  }
  my $ret = '';
  my $pos = 0;
  for (;;) {
    $pos = index($stripped,$str,$pos);
    last if $pos < 0;
    my $start = rindex($stripped,"\n",$pos) + 1;
    my $end = index($stripped,"\n",$pos);
    my $line = substr($stripped,$start,$end-$start);
    $ret .= "$line\n";
    my ($anum) = ($line =~ /^(A\d+)/);
    $anum || die "$anum not found";
    $ret .= `zgrep -e ^$anum $ENV{HOME}/OEIS/names.gz`;
    $pos = $end;
  }
  return $ret;
}












#------------------------------------------------------------------------------

# ($inforef, $inforef, ...)
sub parameter_info_list_to_parameters {
  my @parameters = ([]);
  foreach my $info (@_) {
    next if $info->{'name'} eq 'n_start';
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
      # next unless $choice =~ /DiamondSpiral/;
      # next unless $choice =~ /Gcd/;
      # next unless $choice =~ /LCorn|RationalsTree/;
      next unless $choice =~ /dragon/i;
      # next unless $choice =~ /SierpinskiArrowheadC/;
      # next unless $choice eq 'DiagonalsAlternating';
      my $path_class = "Math::PlanePath::$choice";
      Module::Load::load($path_class);

      my @parameter_info_list = $path_class->parameter_info_list;

      {
        my $path = $path_class->new;
        if (defined $path->{'n_start'}
            && ! $path_class->parameter_info_hash->{'n_start'}) {
          push @parameter_info_list,{ name      => 'n_start',
                                      type      => 'enum',
                                      choices   => [0,1],
                                      default   => $path->default_n_start,
                                    };
        }
      }

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

  if ($info->{'choices'}) {
    my @new_parameters;
    foreach my $p (@$parameters) {
      foreach my $choice (@{$info->{'choices'}}) {
        next if ($info->{'name'} eq 'serpentine_type' && $choice eq 'Peano');
        next if ($info->{'name'} eq 'rotation_type' && $choice eq 'custom');
        push @new_parameters, [ @$p, $info->{'name'}, $choice ];
      }
      if ($info->{'name'} eq 'serpentine_type') {
        push @new_parameters, [ @$p, $info->{'name'}, '100_000_000' ];
        push @new_parameters, [ @$p, $info->{'name'}, '101_010_101' ];
        push @new_parameters, [ @$p, $info->{'name'}, '000_111_000' ];
        push @new_parameters, [ @$p, $info->{'name'}, '111_000_111' ];
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
    my @choices;
    if ($info->{'name'} eq 'radix') { @choices = (2,3,10,16); }
    if ($info->{'name'} eq 'n_start') { @choices = (0,1); }
    if ($info->{'name'} eq 'x_start'
        || $info->{'name'} eq 'y_start') { @choices = ($info->{'default'}); }

    if (! @choices) {
      my $min = $info->{'minimum'} // -5;
      my $max = $min + 10;
      if (# $module =~ 'PrimeIndexPrimes' &&
          $info->{'name'} eq 'level') { $max = 5; }
      # if ($info->{'name'} eq 'arms') { $max = 2; }
      if ($info->{'name'} eq 'rule') { $max = 255; }
      if ($info->{'name'} eq 'round_count') { $max = 20; }
      if ($info->{'name'} eq 'straight_spacing') { $max = 1; }
      if ($info->{'name'} eq 'diagonal_spacing') { $max = 1; }
      if ($info->{'name'} eq 'radix') { $max = 17; }
      if ($info->{'name'} eq 'realpart') { $max = 3; }
      if ($info->{'name'} eq 'wider') { $max = 1; }
      if ($info->{'name'} eq 'modulus') { $max = 32; }
      if ($info->{'name'} eq 'polygonal') { $max = 32; }
      if ($info->{'name'} eq 'factor_count') { $max = 12; }
      if ($info->{'name'} eq 'diagonal_length') { $max = 5; }
      if ($info->{'name'} eq 'height') { $max = 4; }
      if ($info->{'name'} eq 'width') { $max = 4; }
      if ($info->{'name'} eq 'k') { $max = 4; }

      if (defined $info->{'maximum'} && $max > $info->{'maximum'}) {
        $max = $info->{'maximum'};
      }
      if ($info->{'name'} eq 'power' && $max > 6) { $max = 6; }
      @choices = ($min .. $max);
    }

    my @new_parameters;
    foreach my $choice (@choices) {
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

# return true if coprime
sub _coprime {
  my ($x, $y) = @_;
  ### _coprime(): "$x,$y"
  if ($y > $x) {
    ($x,$y) = ($y,$x);
  }
  for (;;) {
    if ($y <= 1) {
      ### result: ($y == 1)
      return ($y == 1);
    }
    ($x,$y) = ($y, $x % $y);
  }
}

sub p_radix {
  my ($p) = @_;
  for (my $i = 0; $i < @$p; $i += 2) {
    if ($p->[$i] eq 'radix') {
      return $p->[$i+1];
    }
  }
  return undef;
}

sub float_error {
  my ($x) = @_;
  if (abs($x - int($x)) < 0.000001) {
    return int($x);
  } else {
    return $x;
  }
}

__END__
