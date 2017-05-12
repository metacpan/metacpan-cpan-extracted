#!/usr/bin/perl -w

# Copyright 2013, 2014 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use List::Util 'min', 'max';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'bit_split_lowtohigh',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
use Math::NumSeq::HafermanCarpet;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  foreach my $n (0 .. 5) {
    my $Seq_1s_init0 = Seq_1s_init0($n);
    my $Seq_1s_init0_by_formula = Seq_1s_init0_by_formula($n);
    my $Seq_1s_init1 = Seq_1s_init1($n);
    my $Seq_1s_init1_by_formula = Seq_1s_init1_by_formula($n);
    printf("%d  %6d %6d%s   %6d %6d%s  %6d %6d\n",
           $n,
           $Seq_1s_init0,
           $Seq_1s_init0_by_formula,
           $Seq_1s_init0 == $Seq_1s_init0_by_formula ? '' : '******',

           $Seq_1s_init1,
           $Seq_1s_init1_by_formula,
           $Seq_1s_init1 == $Seq_1s_init1_by_formula ? '' : '******',

           Array_1s_init0($n),
           Array_1s_init1($n),
          );
  }
  exit 0;

  # num black cells after n iterations  (9^(k+1) - (-5)^(k+1))/14 = 1,4,61,424
  # Array1s(k+1) = 9^(k+1) - 5*Array1s(k)
  # Array1s(0) = 1
  # Array1s(1) = 9^1 - 5*1 = 4
  # Array1s(2) = 9^2 - 5*(9^1 - 5*1)
  #            = 5^0*9^2 - 5^1*9^1 + 5^2*9^0
  # Array1s(3) = 5^0*9^3 - 5^1*9^2 + 5^2*9^1 - 5^3*9^0
  # 5^0*9^0 = 1
  # 5^1*9^0 - 5^2*9^1 = 20
  sub Array_1s_init1 {
    my ($n) = @_;
    return (9**($n+1) - (-5)**($n+1)) / 14;
  }
  sub Hbox {
    my ($n) = @_;
    return 5**$n;
  }

  # Array_1s_init0 = (9^(k+1) - (-5)^(k+1)) / 14   -   (-1)^k * 5^k 
  #                = (9^(k+1) - (-5)^(k+1) - 14*(-5)^k) / 14
  #                = (9^(k+1) - (-5)^(k+1) - 14*(-5)^k) / 14
  #                = (9^(k+1) - -5*(-5)^k - 14*(-5)^k) / 14
  #                = (9^(k+1) + 5*(-5)^k - 14*(-5)^k) / 14
  #                = (9^(k+1) - 9*(-5)^k) / 14

  sub Array_1s_init0 {
    my ($n) = @_;

    return (9**($n+1) - 9*(-5)**$n) / 14;

    # +1 if n odd, -1 if n even
    return Array_1s_init1($n) + (-1)**($n+1) * Hbox($n);
  }

  # Sones = (9^(n+1) - (-5)^(n+1)) / 14 - (1 + (-1)**$n)/2 * 5^n
  #       = (9^(n+1) - (-5)^(n+1) - 7*(1 + (-1)^n) * 5^n) / 14
  #       = (9^(n+1) - (-1)^(n+1)*5*5^n - 7*(1 + (-1)^n) * 5^n) / 14
  #       = (9^(n+1) + (- (-1)^(n+1)*5 - 7*(1 + (-1)^n)) * 5^n) / 14
  #       = (9^(n+1) + (- (-1)^(n+1)*5 - 7 - 7*(-1)^n) * 5^n) / 14
  #       = (9^(n+1) + (5*(-1)^n - 7 + 7*(-1)^n) * 5^n) / 14
  #       = (9^(n+1) + (-2*(-1)^n - 7) * 5^n) / 14
  #       = (9^(n+1) - (2*(-1)^n + 7) * 5^n) / 14       # 7+2=9 or 7-2=5

  sub Seq_1s_init0_by_formula {
    my ($n) = @_;
    return (9**($n+1) - (2*(-1)**$n + 7) * 5**$n) / 14;
    return Array_1s_init1($n) - (1 + (-1)**$n)/2 * Hbox($n);
  }

  # S1ones = (9^(n+1) - (2*(-1)^n + 7) * 5^n) / 14  + 5^n
  #        = (9^(n+1) - (2*(-1)^n + 7) * 5^n  + 14 * 5^n) / 14
  #        = (9^(n+1) - (2*(-1)^n + 7 - 14) * 5^n) / 14
  #        = (9^(n+1) - (2*(-1)^n - 7) * 5^n) / 14

  sub Seq_1s_init1_by_formula {
    my ($n) = @_;
    return (9**($n+1) - (2*(-1)**$n - 7) * 5**$n) / 14;
    return Array_1s_init1($n) - (1 + (-1)**$n)/2 * Hbox($n);
  }


  BEGIN {
    my @count;
    my $seq = Math::NumSeq::HafermanCarpet->new (initial_value => 0);
    sub Seq_1s_init0 {
      my ($n) = @_;
      while ($#count < $n) {
        my $count = 0;
        my $exp = $#count + 1;
        ### $exp
        foreach my $i (0 .. 9**$exp-1) {
          $count += $seq->ith($i);
        }
        ### $count
        $count[$exp] = $count;
      }
      return $count[$n];
    }
  }
  BEGIN {
    my @count;
    my $seq = Math::NumSeq::HafermanCarpet->new (initial_value => 1);
    sub Seq_1s_init1 {
      my ($n) = @_;
      while ($#count < $n) {
        my $count = 0;
        my $exp = $#count + 1;
        ### $exp
        foreach my $i (0 .. 9**$exp-1) {
          $count += $seq->ith($i);
        }
        ### $count
        $count[$exp] = $count;
      }
      return $count[$n];
    }
  }
}
{
  # side axis counts

  # count 1s in initial_value=0, except initial extra 0 in A167910
  # half count 0s in initial_value=1
  # A167910 (4*3^n - 5*2^n + (-2)^n)/20
  # A167910 ,0,0,1,3,13,39,133,399,1261,3783,11605,34815,105469,316407,

  foreach my $bit (1, 0) {
    foreach my $initial_value (0, 1) {
      my $seq = Math::NumSeq::HafermanCarpet->new
        (initial_value => $initial_value,
         radix => 3);
      my $target = 1;
      my $count = 0;
      my @values;
      for (my $i = 0; $i < 3**8; $i++) {
        if ($i == $target) {
          push @values, $count;
          $target *= 3;
        }
        if ($seq->ith($i) == $bit) {
          $count++;
        }
      }
      # shift @values;
      print join(',',@values),"\n";
      require MyOEIS;
      Math::OEIS::Grep->search
        (name => "initial_value=$initial_value bit=$bit",
         array => \@values);
    }
  }
  exit 0;
}


{
  # 81-long morphism
  foreach my $initial_value (0, 1) {
    my $seq = Math::NumSeq::HafermanCarpet->new
      (initial_value => $initial_value);
    foreach my $i (0 .. 80) {
      print $seq->ith($i);
      if ($i % 9 == 8) {
        print "\n";
      }
    }
    print "\n";
  }
  exit 0;
}

{
  # side axis
  # once 0 -> 111
  #      1 -> 010
  #
  # twice 0 -> 010 010 010
  #       1 -> 111 010 111
  #
  # is radix=3 variant
  #
  require Math::PlanePath::ZOrderCurve;
  my $path = Math::PlanePath::ZOrderCurve->new (radix => 3);

  foreach my $initial_value (0, 1) {
    my @values = ($initial_value);
    foreach (1 .. 4) {
      @values = map { $_ ? (0,1,0) : (1,1,1) } @values;
      print join('',@values),"\n";
    }

    {
      my $seq = Math::NumSeq::HafermanCarpet->new
        (initial_value => $initial_value);
      foreach my $i (0 .. $#values) {
        my $got = $values[$i];
        my $n = $path->xy_to_n($i,0);
        my $want = $seq->ith($n);
        die unless $got == $want;
      }
    }
    {
      my $seq = Math::NumSeq::HafermanCarpet->new
        (initial_value => $initial_value,
         radix => 3);
      my $v = join('',@values);
      my $s = join('', map { $seq->ith($_) } 0 .. $#values);
      unless ($v eq $s) {
        print "vvv $v\n";
        print "seq $s\n";
        die;
      }
    }

    require MyOEIS;
    $#values = 70;
    Math::OEIS::Grep->search
      (name => "centre axis initial_value=$initial_value",
       array => \@values);
  }
  exit 0;
}

{
  # centre axis
  # 0 -> 11 first point   0 -> 111 later points
  # 1 -> 01               1 -> 101
  #
  # twice 0 -> 01101 first point
  #       1 -> 11101
  #
  # 1   0
  # 3   11
  # 9   01101
  # 27  11101101111101
  # 81  01101101111101101111101101101101101111101
  #      123456789                    n
  #      001001002001001002001001003  low 0-trits
  #
  # cf A014578 is 1->110, 0->111
  #
  foreach my $initial (0, 1) {
    my @values = ($initial);
    foreach (1 .. 5) {
      print 2*scalar(@values)-1,"  ",join('',@values),"\n";

      my @new_values;
      push @new_values, shift @values ? (0,1) : (1,1);
      foreach my $value (@values) {
        push @new_values, $value ? (1,0,1) : (1,1,1);
      }
      @values = @new_values;
    }

    require MyOEIS;
    $#values = 70;
    shift @values;
    Math::OEIS::Grep->search(name => "centre axis starting $initial",
                             array => \@values);
  }
  exit 0;
}






{
  my $str;
  sub haferman_by_morphism {
    my ($i) = @_;
    while ($i >= length($str)) {
      $str =~ s{(.)}{
        $1 ? "010101010" : "111111111"
      }eg;
    }
    return substr($str,$i,1) + 0;
  }
}


{
  # Haferman carpet values by paths

  # centred starting from 1
  # XorY axis = A014578 count low 0-trits, mod 2, skip initial origin point

  # centred starting from 0
  # XorY axis = A014578 count low 0-trits, mod 2
  # rule=20 line 1,2 maybe A182581 count low base-3 zeros taken mod 2

  require MyOEIS;
  require Math::NumSeq::PlanePathCoord;
  my @choices = @{Math::NumSeq::PlanePathCoord->parameter_info_hash
      ->{'planepath'}->{'choices'}};
  @choices = grep {$_ ne 'BinaryTerms'} @choices; # bit slow yet
  require Module::Load;
  foreach my $path_name (@choices) {
    print "$path_name\n";
    my $path_class = "Math::PlanePath::$path_name";
    Module::Load::load($path_class);
    my $parameters = parameter_info_list_to_parameters($path_class->parameter_info_list);
  PATH: foreach my $p (@$parameters) {
      my $name = "$path_name  ".join(',',@$p);
      my $path = $path_class->new (@$p);
      my @values;
      for (my $n = $path->n_start+1; @values < 35 && $n < 200; $n++) {
        my ($x,$y) = $path->n_to_xy($n) or next PATH;
        if (abs($x) > 300 || abs($y) > 300) {
          print " skip too big\n";
          next PATH;
        }
        my $value = xy_to_haferman_centred($x,$y);

        next PATH if ! defined $value;
        # push @values, $value;

        if (! $value) {
          push @values, $n;
        }
      }
      Math::OEIS::Grep->search(name => $name,
                               array => \@values);
    }
  }
  exit 0;
}

{
  # print xy_to_haferman_quad()

  foreach my $y (reverse 0 .. 0) {
    # nforeach my $x (0 .. 54) {
    foreach my $x (-27 .. 27) {
      my $value = xy_to_haferman_centred($x,$y);
      print $value ? '*' : ' ';
    }
    print "\n";
  }
  require Math::NumSeq::OEIS;
  my $seq = Math::NumSeq::OEIS->new (anum => 'A014578');
  foreach my $i (0 .. 54) {
    my ($i,$value) = $seq->next;
    print $value ? '@' : ' ';
  }
  exit 0;
}
{
  sub xy_to_haferman_centred {
    my ($x,$y) = @_;
    my ($pow,$exp) = round_down_pow(2*max(abs($x),abs($y))+1, 9);
    $pow *= 9;
    $pow = ($pow-1)/2;
    $x += $pow;
    $y += $pow;
    $x >= 0 or die $x;
    $y >= 0 or die $y;
    return xy_to_haferman_quad($x, $y);
  }
}
{
  my $size; BEGIN { $size = 1; }
  my @xy; BEGIN { @xy = ([1]); }
  sub xy_to_haferman_quad {
    my ($x,$y) = @_;
    if ($x < 0 || $y < 0) {
      return undef;
    }
    # $x = abs($x);
    # $y = abs($y);
    if ($x >= $size || $y >= $size) {
      foreach (1,2) {
        my @newxy;
        foreach my $x (0 .. $size-1) {
          foreach my $y (0 .. $size-1) {
            if ($xy[$x][$y]) {
              $newxy[3*$x+0][3*$y+0] = 0;
              $newxy[3*$x+1][3*$y+0] = 1;
              $newxy[3*$x+2][3*$y+0] = 0;
              $newxy[3*$x+0][3*$y+1] = 1;
              $newxy[3*$x+1][3*$y+1] = 0;
              $newxy[3*$x+2][3*$y+1] = 1;
              $newxy[3*$x+0][3*$y+2] = 0;
              $newxy[3*$x+1][3*$y+2] = 1;
              $newxy[3*$x+2][3*$y+2] = 0;
            } else {
              $newxy[3*$x+0][3*$y+0] = 1;
              $newxy[3*$x+1][3*$y+0] = 1;
              $newxy[3*$x+2][3*$y+0] = 1;
              $newxy[3*$x+0][3*$y+1] = 1;
              $newxy[3*$x+1][3*$y+1] = 1;
              $newxy[3*$x+2][3*$y+1] = 1;
              $newxy[3*$x+0][3*$y+2] = 1;
              $newxy[3*$x+1][3*$y+2] = 1;
              $newxy[3*$x+2][3*$y+2] = 1;
            }
          }
        }
        @xy = @newxy;
        $size *= 3;
        # print "xy_to_haferman_quad() size=$size\n";
      }
    }
    return $xy[$x][$y];
  }
}

{
  # not found
  use lib 'xt'; require MyOEIS;
  require Math::NumSeq::HafermanZ;
  my $seq = Math::NumSeq::HafermanZ->new;
  my @values;
  foreach my $i (1 .. 50) {
    push @values, $seq->ith($i) ? 0 : 1;
  }
  print join(',',@values),"\n";
  Math::OEIS::Grep->search(array=>\@values);
  exit 0;
}

{
  # carpet in .png image file

  require Image::Base::PNGwriter;
  my $scale = 6;
  my $depth = 6;
  my $width = $scale*3**$depth;
  my $height = $scale*3**$depth;
  my $image = Image::Base::PNGwriter->new (-width => $width,
                                           -height => $height);
  my ($draw0,$draw1);
  $draw0 = sub {
    my ($x,$y,$len) = @_;
    if ($len/3 <= $scale) {
      $image->rectangle($x,$y,$x+$len-1,$y+$len-1, '#000000', 1);
    } else {
      $len /= 3;
      foreach my $xo (0 .. 2) {
        foreach my $yo (0 .. 2) {
          $draw1->($x+$xo*$len,$y+$yo*$len,$len);
        }
      }
    }
  };
   my @table = (1,0,1, 0,0,0, 1,0,1);
  # my @table = (1,0,1, 0,1,0, 1,0,1);
  # my @table = (0,1,0, 1,0,1, 0,1,0);
  $draw1 = sub {
    my ($x,$y,$len) = @_;
    if ($len/3 <= $scale) {
      $image->rectangle($x,$y,$x+$len-1,$y+$len-1, '#FFFFFF', 1);
    } else {
      $len /= 3;
      foreach my $xo (0 .. 2) {
        foreach my $yo (0 .. 2) {
          my $func = ($table[$xo+3*$yo] ? $draw1 : $draw0);
          $func->($x+$xo*$len,$y+$yo*$len,$len);
        }
      }
    }
  };

  $draw1->(0,0, 3**$depth);
  # $image->save('/dev/stdout');
  $image->save('/tmp/x.png');
  system('ls -l /tmp/x.png');
  system('xzgv /tmp/x.png');
  exit 0;
}







#------------------------------------------------------------------------------

# ($inforef, $inforef, ...)
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
#------------------------------------------------------------------------------
