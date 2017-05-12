#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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

# uncomment this to run the ### lines
#use Smart::Comments;


{
  # dx,dy on even radix
  require Math::PlanePath::PeanoCurve;
  require Math::BigInt;
  require Math::BaseCnv;
  foreach my $radix (4, 2, 6, 8) {
    print "radix=$radix\n";
    my $path = Math::PlanePath::PeanoCurve->new (radix => $radix);
    my $limit = 4000000000;
    {
      my %seen_dx;
      for my $len (0 .. 8) {
        for my $high (1 .. $radix-1) {
          my $n = Math::BigInt->new($high);
          foreach (1 .. $len) { $n *= $radix; $n += $radix-1; }

          my ($dx,$dy) = $path->n_to_dxdy($n);
          $dx = abs($dx);
            my ($x,$y) = $path->n_to_xy($n);
            my $xr = Math::BaseCnv::cnv($x,10,$radix);
            my $dr = Math::BaseCnv::cnv($dx,10,$radix);
            my $nr = Math::BaseCnv::cnv($n,10,$radix);
            print "N=$n [$nr]  dx=$dx [$dr]  x=[$xr]\n";
          unless ($seen_dx{$dx}++) {
          }
        }
      }
    }
    {
      my %seen_dy;
      for my $len (0 .. 8) {
        for my $high (1 .. $radix-1) {
          my $n = Math::BigInt->new($high);
          foreach (1 .. $len) { $n *= $radix; $n += $radix-1; }

          my ($dx,$dy) = $path->n_to_dxdy($n);
          $dy = abs($dy);
          unless ($seen_dy{$dy}++) {
            my $dr = Math::BaseCnv::cnv($dy,10,$radix);
            my $nr = Math::BaseCnv::cnv($n,10,$radix);
            print "N=$n [$nr]  dy=$dy [$dr]\n";
          }
        }
      }
    }
    print "\n";
  }
  exit 0;
}

{
  # abs(dY) = count low 2-digits, mod 2
  # abs(dX) = opposite, 1-abs(dY)
  #                                        x x
  # vertical when odd number of low 2s  ..0222
  # N+1 carry propagates to change      ..1000
  #                                       y y
  # high y+1 complements x from 0->2 so X unchanged
  # Y becomes Y+1 02 -> 10, or if complement then Y-1 20 -> 12
  #
  my $radix = 3;
  require Math::PlanePath::PeanoCurve;
  require Math::NumSeq::PlanePathDelta;
  require Math::NumSeq::DigitCountLow;
  require Math::BigInt;
  require Math::BaseCnv;
  my $path = Math::PlanePath::PeanoCurve->new (radix => $radix);
  my $seq = Math::NumSeq::PlanePathDelta->new (planepath_object => $path,
                                               delta_type => 'AbsdX');
  my $cnt = Math::NumSeq::DigitCountLow->new (radix => 3, digit => 2);
  foreach my $n (0 .. 40) {
    my ($dx,$dy) = $path->n_to_dxdy($n);
    my $absdx = abs($dx);
    my $absdy = abs($dy);
    my $c = $cnt->ith($n);
    my $by_c = $c & 1;
    my $diff = $absdy == $by_c ? '' : '  ***';

    # my $n = $n+1;
    my $nr = Math::BaseCnv::cnv($n,10,$radix);

    printf "%3d %7s  %2d,%2d  low=%d%s\n",
      $n, $nr, abs($dx),abs($dy), $c, $diff;
    # print "$n,";
    if ($absdx != 0) {
    }
  }
  exit 0;
}

{
  # Dir4 maximum
  my $radix = 6;
  require Math::PlanePath::PeanoCurve;
  require Math::NumSeq::PlanePathDelta;
  require Math::BigInt;
  require Math::BaseCnv;
  my $path = Math::PlanePath::PeanoCurve->new (radix => $radix);
  my $seq = Math::NumSeq::PlanePathDelta->new (planepath_object => $path,
                                               delta_type => 'Dir4');
  my $dir4_max = 0;
  foreach my $n (0 .. 600000) {
    # my $n = Math::BigInt->new(2)**$level - 1;
    my $dir4 = $seq->ith($n);
    if ($dir4 > $dir4_max) {
      $dir4_max = $dir4;
      my ($dx,$dy) = $path->n_to_dxdy($n);
      my $nr = Math::BaseCnv::cnv($n,10,$radix);
      printf "%7s  %2b,\n    %2b %8.6f\n", $nr, abs($dx),abs($dy), $dir4;
    }
  }
  exit 0;
}

{
  # axis increasing
  my $radix = 4;
  my $rsquared = $radix * $radix;
  my $re = '.' x $radix;

  require Math::NumSeq::PlanePathN;
  foreach my $line_type ('Y_axis', 'X_axis', 'Diagonal') {
  OUTER: foreach my $serpentine_num (0 .. 2**$rsquared-1) {
      my $serpentine_type = sprintf "%0*b", $rsquared, $serpentine_num;
      # $serpentine_type = reverse $serpentine_type;
      $serpentine_type =~ s/($re)/$1_/go;
      ### $serpentine_type

      my $seq = Math::NumSeq::PlanePathN->new
        (
         planepath => "WunderlichSerpentine,radix=$radix,serpentine_type=$serpentine_type",
         line_type => $line_type,
        );
      ### $seq

      # my $path = Math::NumSeq::PlanePathN->new
      #   (
      #    e,radix=$radix,serpentine_type=$serpentine_type",
      #    line_type => $line_type,
      #   );

      my $prev = -1;
      for (1 .. 1000) {
        my ($i, $value) = $seq->next;
        if ($value <= $prev) {
          # print "$line_type $serpentine_type   decrease at i=$i  value=$value cf prev=$prev\n";
          # my $path = $seq->{'planepath_object'};
          # my ($prev_x,$prev_y) = $path->n_to_xy($prev);
          # my ($x,$y) = $path->n_to_xy($value);
          # # print "  N=$prev $prev_x,$prev_y  N=$value $x,$y\n";
          next OUTER;
        }
        $prev = $value;
      }
      print "$line_type $serpentine_type   all increasing\n";
    }
  }
  exit 0;
}

{
  # max Dir4

  my $radix = 4;

  require Math::BaseCnv;

  print 4-atan2(2,1)/atan2(1,1)/2,"\n";

  require Math::NumSeq::PlanePathDelta;
  my $seq = Math::NumSeq::PlanePathDelta->new (planepath => "PeanoCurve,radix=$radix",
                                               delta_type => 'Dir4');
  my $dx_seq = Math::NumSeq::PlanePathDelta->new (planepath => "PeanoCurve,radix=$radix",
                                                  delta_type => 'dX');
  my $dy_seq = Math::NumSeq::PlanePathDelta->new (planepath => "PeanoCurve,radix=$radix",
                                                  delta_type => 'dY');
  my $max = 0;
  for (1 .. 10000000) {
    my ($i, $value) = $seq->next;

  # foreach my $k (1 .. 1000000) {
  #   my $i = $radix ** (4*$k+3) - 1;
  #   my $value = $seq->ith($i);

    if ($value > $max
        # || $i == 0b100011111
       ) {
      my $dx = $dx_seq->ith($i);
      my $dy = $dy_seq->ith($i);
      my $ri = Math::BaseCnv::cnv($i,10,$radix);
      my $rdx = Math::BaseCnv::cnv($dx,10,$radix);
      my $rdy = Math::BaseCnv::cnv($dy,10,$radix);
      my $f = $dy ? $dx/$dy : -1;
      printf "%d %s %.5f  %s %s   %.3f\n", $i, $ri, $value, $rdx,$rdy, $f;
      $max = $value;
    }
  }

  exit 0;
}
