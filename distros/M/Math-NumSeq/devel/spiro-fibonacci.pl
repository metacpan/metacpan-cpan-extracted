#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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

require 5;
use strict;

# uncomment this to run the ### lines
#use Smart::Comments;

{
  # delta

  require Math::PlanePath::SquareSpiral;
  my $path = Math::PlanePath::SquareSpiral->new;

  require Math::NumSeq::SpiroFibonacci;
  my $seq = Math::NumSeq::SpiroFibonacci->new;
  $seq->next;
  $seq->next;

  foreach (1 .. 200) {
    my $queue = $seq->{'queue'};
    my $queuelen = scalar(@$queue);
    my ($n, $value) = $seq->next;

    my $pn = n_to_closest($path,$n);
    my ($dx,$dy) = n_to_dxdy($path,$n-1);
    my $dir = dxdy_to_dir($dx,$dy);
    my $diff = $n - $pn;

    my $xx = ($queuelen != $diff ? '  ***' : '');
    printf "%3d dir=%d %3d  %2d %2d%s\n",
      $n, $dir, $pn, $diff, $queuelen, $xx;
  }
  exit 0;
}


sub n_to_dxdy {
  my ($path, $n) = @_;
  my ($x,$y) = $path->n_to_xy($n);
  my ($next_x,$next_y) = $path->n_to_xy($n+1);
  return ($next_x - $x,
          $next_y - $y);
}

  # with Y reckoned increasing upwards
sub dxdy_to_dir {
  my ($dx, $dy) = @_;
  if ($dx > 0) { return 0; }  # east
  if ($dx < 0) { return 2; }  # west
  if ($dy > 0) { return 1; }  # north
  if ($dy < 0) { return 3; }  # south
  die "oops unrecognised $dx,$dy";
}

sub n_to_closest {
  my ($path, $n) = @_;

  my ($x,$y) = $path->n_to_xy($n);
  my $pn = 0;
  foreach my $dxdy ([0,1],[0,-1],
                    [1,0],[-1,0]) {
    my ($dx,$dy) = @$dxdy;
    my $dn = $path->xy_to_n($x+$dx,$y+$dy);
    ### straight: $dn
    if ($dn < $n-1 && $dn > $pn) {
      ### straight at: "i=$n,x=$x,y=$y   dx=$dx dy=$dy pn=$dn"
      $pn = $dn;
    }
  }
  if (! $pn) {
    foreach my $dxdy ([1,1],[1,-1],
                      [-1,1],[-1,-1]) {
      my ($dx,$dy) = @$dxdy;
      my $dn = $path->xy_to_n($x+$dx,$y+$dy);
      ### diag: $dn
      if ($dn < $n-1 && $dn > $pn) {
        ### diagonal at: "i=$n,x=$x,y=$y   dx=$dx dy=$dy pn=$dn"
        $pn = $dn;
      }
    }
  }
  if (! $pn) {
    die "oops, not found for n=$n";
  }
  return $pn;
}
