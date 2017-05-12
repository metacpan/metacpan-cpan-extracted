#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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
use Math::Libm 'M_PI', 'hypot';


{
  require Math::PlanePath::QuintetCurve;
  require Math::PlanePath::QuintetCentres;
  my $f = Math::PlanePath::QuintetCurve->new (arms=>4);
  my $c = Math::PlanePath::QuintetCentres->new (arms=>4);
  my $width = 5;
  my %saw;
  my $n_end = 5**($width-1) * $f->arms_count;
  foreach my $n (0 .. $n_end) {
    my ($x,$y) = $f->n_to_xy($n);

    my $cn = $c->xy_to_n($x,$y) // -1;

    my $cr  = $c->xy_to_n($x+1,$y) // -1;
    my $cur = $c->xy_to_n($x+1,$y+1) // -1;
    my $cu  = $c->xy_to_n($x,  $y+1) // -1;  # <-----
    my $cul = $c->xy_to_n($x-1,$y+1) // -1;  # <-----
    my $cl  = $c->xy_to_n($x-1,$y) // -1;    # <-----
    my $cdl = $c->xy_to_n($x-1,$y-1) // -1;
    my $cd  = $c->xy_to_n($x,  $y-1) // -1;
    my $cdr = $c->xy_to_n($x+1,$y-1) // -1;

    if ($n == $cn) { $saw{'n'}   = 0; }
    if ($n == $cr) { $saw{'r'}   = 1; }
    if ($n == $cur) { $saw{'ur'} = 2; }
    if ($n == $cu) { $saw{'u'}   = 3; }
    if ($n == $cul) { $saw{'ul'} = 4; }
    if ($n == $cl) { $saw{'l'}   = 5; }
    if ($n == $cdl) { $saw{'dl'} = 6; }
    if ($n == $cd) { $saw{'d'}   = 7; }
    if ($n == $cdr) { $saw{'dr'} = 8; }

    unless ($n == $cn
            || $n == $cr
            || $n == $cur
            || $n == $cu
            || $n == $cul
            || $n == $cl
            || $n == $cdl
            || $n == $cd
            || $n == $cdr) {
      die "$n";
    }

    # print "$n5 $cn5 $ch5 $cw5 $cu5   $bad\n";
  }
  my $saw = join(',', sort {$saw{$a}<=>$saw{$b}} keys %saw);
  print "$saw     to n_end=$n_end\n";
  exit 0;
}

{
  require Math::BaseCnv;
  require Math::PlanePath::QuintetCurve;
  require Math::PlanePath::QuintetCentres;
  my $f = Math::PlanePath::QuintetCurve->new;
  my $c = Math::PlanePath::QuintetCentres->new;
  my $width = 5;
  my %saw;
  foreach my $n (0 .. 5**($width-1)) {
    my $n5 = sprintf '%*s', $width, Math::BaseCnv::cnv($n,10,5);
    my ($x,$y) = $f->n_to_xy($n);

    my $cn = $c->xy_to_n($x,$y) || -1;
    my $cn5 = sprintf '%*s', $width, Math::BaseCnv::cnv($cn,10,5);

    my $rx = $x + 1;
    my $ry = $y;
    my $cr = $c->xy_to_n($rx,$ry) || -1;
    my $cr5 = sprintf '%*s', $width, Math::BaseCnv::cnv($cr,10,5);

    my $urx = $x + 1;
    my $ury = $y + 1;
    my $cur = $c->xy_to_n($urx,$ury) || -1;
    my $cur5 = sprintf '%*s', $width, Math::BaseCnv::cnv($cur,10,5);

    my $ux = $x;
    my $uy = $y + 1;
    my $cu = $c->xy_to_n($ux,$uy) || -1;
    my $cu5 = sprintf '%*s', $width, Math::BaseCnv::cnv($cu,10,5);

    my $ulx = $x - 1;
    my $uly = $y + 1;
    my $cul = $c->xy_to_n($ulx,$uly) || -1;
    my $cul5 = sprintf '%*s', $width, Math::BaseCnv::cnv($cul,10,5);

    my $lx = $x - 1;
    my $ly = $y;
    my $cl = $c->xy_to_n($lx,$ly) || -1;
    my $cl5 = sprintf '%*s', $width, Math::BaseCnv::cnv($cl,10,5);

    my $dlx = $x - 1;
    my $dly = $y - 1;
    my $cdl = $c->xy_to_n($dlx,$dly) || -1;
    my $cdl5 = sprintf '%*s', $width, Math::BaseCnv::cnv($cdl,10,5);

    my $dx = $x;
    my $dy = $y - 1;
    my $cd = $c->xy_to_n($dx,$dy) || -1;
    my $cd5 = sprintf '%*s', $width, Math::BaseCnv::cnv($cd,10,5);

    my $drx = $x + 1;
    my $dry = $y - 1;
    my $cdr = $c->xy_to_n($drx,$dry) || -1;
    my $cdr5 = sprintf '%*s', $width, Math::BaseCnv::cnv($cdr,10,5);

    if ($n == $cn) { $saw{'n'}   = 0; }
    if ($n == $cr) { $saw{'r'}   = 1; }
    if ($n == $cur) { $saw{'ur'} = 2; }
    if ($n == $cu) { $saw{'u'}   = 3; }
    if ($n == $cul) { $saw{'ul'} = 4; }
    if ($n == $cl) { $saw{'l'}   = 5; }
    if ($n == $cdl) { $saw{'dl'} = 6; }
    if ($n == $cd) { $saw{'d'}   = 7; }
    if ($n == $cdr) { $saw{'dr'} = 8; }

    my $bad = ($n == $cn
               || $n == $cr
               || $n == $cur
               || $n == $cu
               || $n == $cul
               || $n == $cl
               || $n == $cdl
               || $n == $cd
               || $n == $cdr
               ? ''
               : '  ******');

    # print "$n5 $cn5 $ch5 $cw5 $cu5   $bad\n";
  }
  my $saw = join(',', sort {$saw{$a}<=>$saw{$b}} keys %saw);
  print "$saw\n";
  exit 0;
}

{
  my $x = 1;
  my $y = 0;
  for (my $level = 1; $level < 20; $level++) {
    # (x+iy)*(2+i)
    ($x,$y) = (2*$x - $y, $x + 2*$y);
    if (abs($x) >= abs($y)) {
      $x -= ($x<=>0);
    } else {
      $y -= ($y<=>0);
    }
    print "$level $x,$y\n";
  }
  exit 0;
}


