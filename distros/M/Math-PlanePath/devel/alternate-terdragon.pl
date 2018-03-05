#!/usr/bin/perl -w

# Copyright 2018 Kevin Ryde

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
use List::Util 'min', 'max';
use Math::PlanePath::AlternateTerdragon;
use Math::PlanePath;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
use List::Pairwise;
use Math::BaseCnv;
use lib 'xt';
use MyOEIS;

# uncomment this to run the ### lines
# use Smart::Comments;

# # skip low zeros
# # 1 left
# # 2 right
# ones(n) - ones(n+1)

# 1*3^k  left
# 2*3^k  right


{
  foreach my $arms (1 .. 6) {
    print "arms=$arms\n";
    my $path = Math::PlanePath::AlternateTerdragon->new (arms => $arms);
    my $sum_max = 0;
    my $sum_min = 0;
    my $diff_max = 0;
    my $diff_min = 0;
    my $sum_first_neg;
    my $diff_first_neg;
    foreach my $n (0 .. 10000) {
      my ($x,$y) = $path->n_to_xy($n);
      my $s = $x + $y;
      $sum_max = max($sum_max, $s);
      $sum_min = min($sum_min, $s);
      if (! defined $sum_first_neg && $s<0) { $sum_first_neg = $n; }
      my $d = $x - $y;
      $diff_max = max($diff_max, $d);
      $diff_min = min($diff_min, $d);
      if (! defined $diff_first_neg && $d<0) { $diff_first_neg = $n; }
    }
    $sum_first_neg //= 'none';
    $diff_first_neg //= 'none';
    print " sum  $sum_min to $sum_max  first neg at $sum_first_neg\n";
    print " diff  $diff_min to $diff_max  first neg at $diff_first_neg\n";
  }
  exit 0;
}

{
  # initial points picture for the POD

  require Image::Base::Text;
  my $path = Math::PlanePath::AlternateTerdragon->new;
  my $diagonal = 2;
  my $xscale = 6;
  my $yscale = 3;
  my $xmax = 7;
  my $ymin = -1;
  my $ymax = 2;
  my $width = ($xmax+4)*$xscale;
  my $height = ($ymax - $ymin + 2)*$yscale;
  ### size: "$width,$height"
  my $image = Image::Base::Text->new (-width => $width,
                                      -height => $height);
  $image->rectangle (0,0, $width-1,$height-1, ' ');
  my $transform = sub {
    my ($x,$y) = @_;
    return (($x+1)*$xscale+5, $height - ($y-($ymin-1))*$yscale);
  };
  foreach my $y ($ymin .. $ymax) {
    my ($px,$py) = $transform->(0,$y);
    my $str = sprintf "Y=%-2d ", $y;
    my $offset = length($str) + 2;
    foreach my $i (0 .. length($str)-1) {
      $image->xy($px-$offset+$i, $py, substr($str,$i,1));
    }
  }
  foreach my $y ($ymin .. $ymax) {
    foreach my $x (0 .. $xmax) {
      next if ($x+$y)%2;
      $path->xyxy_to_n_list_either($x,$y, $x+2,$y) or next;

      my ($px1,$py1) = $transform->($x,$y);
      my ($px2,$py2) = $transform->(min($x+2,$xmax),$y);
      ### line: "$x,$y pixels $px1 to $px2, $py1"
      foreach my $px ($px1 .. $px2) {
        ### char: "$px,$py1"
        $image->xy ($px, $py1, '-');
      }
    }
  }
  foreach my $y ($ymin .. $ymax) {
    foreach my $x (0 .. $xmax) {
      next if ($x+$y) % 2;
      my @n_list = $path->xy_to_n_list($x,$y) or next;
      my $str = ' '.join(',',@n_list).' ';
      my ($px,$py) = $transform->($x,$y);

      ### at: "$x,$y pixels $px, $py"
      ### @n_list
      ### $str
      $py >= 0 || die;
      $py < $height || die;
      $px >= 0 || die;
      $px < $width || die;

      my $offset = int(length($str)/2);
      foreach my $i (0 .. length($str)-1) {
        $image->xy($px-$offset+$i, $py, substr($str,$i,1));
      }

      foreach my $dx (-1,1) {
        foreach my $dy (-1,1) {
          $path->xyxy_to_n_list_either($x,$y, $x+$dx,$y+$dy) or next;
          $image->xy ($px+$diagonal*$dx, $py-$dy, ($dx*$dy > 0 ? '/' : '\\'));
        }
      }
    }
  }
  my $str = $image->save_string;
  print $str;
  exit 0;
}

{
  # arms=6 sample points for the POD

  my $path = Math::PlanePath::AlternateTerdragon->new (arms => 6);
  my $show = sub {
    my ($x,$y) = @_;
    my @n_list = $path->xy_to_n_list($x,$y);
    [join(',',@n_list)];
  };

  print "
                  \\         /             \\           /
                   \\       /               \\         /
                --- @{$show->(-1,1)} ----------------- @{$show->(1,1)} ---
                  /        \\               /         \\
     \\           /          \\             /           \\          /
      \\         /            \\           /             \\        /
    --- @{$show->(-2,0)} ------------- @{$show->(0,0)} -------------- @{$show->(2,0)} ---
      /         \\            /           \\             /        \\
     /           \\          /             \\           /          \\
                  \\        /               \\         /
               ---- @{$show->(-1,-1)} ---------------- @{$show->(1,-1)} ---
                  /        \\               /         \\
                 /          \\             /           \\
";
  exit 0;
}

{
  # segments by direction
  # A092236, A135254, A133474
  # A057083 half term, offset from 3^k, A103312 similar

  my $path = Math::PlanePath::AlternateTerdragon->new;
  $path->n_to_xy(5);
  exit 0;
}
