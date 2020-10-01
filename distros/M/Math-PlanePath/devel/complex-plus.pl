#!/usr/bin/perl -w

# Copyright 2019 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use POSIX;
use List::Util 'min', 'max';
use Math::BaseCnv;
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
use Math::PlanePath::ComplexPlus;
use lib 'xt';
use MyOEIS;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # picture of ComplexPlus Gray one bit different, cf TA

  require Image::Base::GD;
  my $width = 900;
  my $height = 600;
  my $scale = 20;
  my $ox = int($width * .7);
  my $oy = int($height * .7);

  my $transform = sub {
    my ($x,$y) = @_;
    $x *= $scale;
    $y *= $scale;
    $x += $ox;
    $y += $oy;
    return ($x,$height-1-$y);
  };

  my @dir4_to_dx = (1,0,-1,0);
  my @dir4_to_dy = (0,1,0,-1);

  require Math::PlanePath::ComplexPlus;
  my $path = Math::PlanePath::ComplexPlus->new;
  my $image = Image::Base::GD->new (-height => $height,
                                    -width  => $width);
  $image->rectangle(0,0, $width-1,$height-1, 'black');
  $image->ellipse($transform->(-.2,-.2),
                  $transform->(.2,.2),
                  'red', 1);
  foreach my $n (0 .. 2**8-1) {
    my ($x,$y) = $path->n_to_xy($n);
    my $n_gray = Gray($n);

    foreach my $dir4 (0 .. 3) {
      my $dx = $dir4_to_dx[$dir4];
      my $dy = $dir4_to_dy[$dir4];
      my $x2 = $x + $dx;
      my $y2 = $y + $dy;
      my $n_dir = $path->xy_to_n($x2,$y2) // next;
      my $n_dir_gray = Gray($n_dir);
      ### neighbour: sprintf "%d to %d  Gray %b to %b", $n, $n_dir, $n_gray, $n_dir_gray
      if (CountOneBits($n_gray ^ $n_dir_gray) == 1) {
        $image->line($transform->($x,$y),
                     $transform->($x2,$y2),
                     'white');
      }
    }
  }
  my $filename = '/tmp/gray.png';
  $image->save($filename);
  require IPC::Run;
  IPC::Run::start(['xzgv',$filename],'&');
  exit 0;
}
{
  # Gray codes
  my $path = Math::PlanePath::ComplexPlus->new;

  # {
  #   my $n = $path->xy_to_n(0,-1);
  #   print "$n\n";
  #   $n = $path->xy_to_n(0,1);
  #   print "$n\n";
  # }

  foreach my $y (reverse -5 .. 5) {
    foreach my $x (-5 .. 5) {
      my $n = $path->xy_to_n($x,$y);
      if (defined $n) {
        $n = sprintf '%b', Gray($n);
      } else {
        $n = '';
      }
      printf " %8s", $n;
    }
    print "\n";
  }
  exit 0;
}



sub Gray {
  my ($n) = @_;
  require Math::PlanePath::GrayCode;
  my $digits = [ digit_split_lowtohigh($n,2) ];
  Math::PlanePath::GrayCode::_digits_to_gray_reflected($digits,2);
  return digit_join_lowtohigh($digits,2);
}
CHECK {
  Gray(0) == 0 or die;
}

sub CountOneBits {
  my ($n) = @_;
  my $count = 0;
  for ( ; $n; $n>>=1) {
    $count += ($n & 1);
  }
  return $count;
}
