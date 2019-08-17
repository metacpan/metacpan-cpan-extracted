#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2019 Kevin Ryde

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
use Test;
use Math::BigInt try => 'GMP';
plan tests => 27;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::DragonMidpoint;

# uncomment this to run the ### lines
# use Smart::Comments '###';


#------------------------------------------------------------------------------
# A090678   0=straight, 1=not straight, except A090678 has extra initial 1,1

MyOEIS::compare_values
  (anum => 'A090678',
   func => sub {
     my ($count) = @_;
     my @got = (1,1);
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath=>'DragonMidpoint',
                                                turn_type => 'NotStraight');
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A203175 figure boundary length to N=2^k-1

MyOEIS::compare_values
  (anum => 'A203175',
   name => 'boundary length',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::DragonMidpoint->new;
     my @got = (1,1,2);
     for (my $k = 0; @got < $count; $k++) {
       push @got, MyOEIS::path_n_to_figure_boundary($path, 2**$k-1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A077860 -- Y at N=2^k, starting k=1 N=2

# Re -(i+1)^k + i-1
{
  require Math::Complex;
  my $path = Math::PlanePath::DragonMidpoint->new;
  my $b = Math::Complex->make(1,1);
  foreach my $k (1 .. 10) {
    my $n = 2**$k;
    my ($x,$y) = $path->n_to_xy($n);
    my $c = $b; foreach (1 .. $k) { $c *= $b; }
    $c *= Math::Complex->make(0,-1);
    $c += Math::Complex->make(-1,1);
    ok ($c->Re, $x);
    ok ($c->Im, $y);
    # print $x,",";
    # print $c->Re,",";
    # print $c->Im,",";
  }
}

MyOEIS::compare_values
  (anum => 'A077860',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::DragonMidpoint->new;
     my @got;
     for (my $n = Math::BigInt->new(2); @got < $count; $n *= 2) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A073089 -- abs(dY), so 1 if step vertical, 0 if horizontal
#            with extra leading 0

MyOEIS::compare_values
  (anum => 'A073089',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::DragonMidpoint->new;
     my @got = (0);
     my ($prev_x, $prev_y) = $path->n_to_xy (0);
     for (my $n = $path->n_start + 1; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       if ($x == $prev_x) {
         push @got, 1;  # vertical
       } else {
         push @got, 0;  # horizontal
       }
       ($prev_x,$prev_y) = ($x,$y);
     }
     return \@got;
   });

# A073089_func vs b-file
MyOEIS::compare_values
  (anum => q{A073089},
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       push @got, A073089_func($n);
     }
     return \@got;
   });


# A073089_func vs path
{
  my $path = Math::PlanePath::DragonMidpoint->new;
  my ($prev_x, $prev_y) = $path->n_to_xy (0);
  my $bad = 0;
  foreach my $n (0 .. 0x2FFF) {
    my ($x, $y) = $path->n_to_xy ($n);
    my ($nx, $ny) = $path->n_to_xy ($n+1);
    my $path_value = ($x == $nx
                      ? 1   # vertical
                      : 0); # horizontal

    my $a_value = A073089_func($n+2);

    if ($path_value != $a_value) {
      MyTestHelpers::diag ("diff n=$n path=$path_value acalc=$a_value");
      MyTestHelpers::diag ("  xy=$x,$y  nxy=$nx,$ny");
      last if ++$bad > 10;
    }
  }
  ok ($bad, 0, "A073089_func()");
}

sub A073089_func {
  my ($n) = @_;
  ### A073089_func: $n
  for (;;) {
    if ($n <= 1) { return 0; }
    if (($n % 4) == 2) { return 0; }
    if (($n % 8) == 7) { return 0; }
    if (($n % 16) == 13) { return 0; }

    if (($n % 4) == 0) { return 1; }
    if (($n % 8) == 3) { return 1; }
    if (($n % 16) == 5) { return 1; }

    if (($n % 8) == 1) {
      $n = ($n-1)/2+1;  # 8n+1 -> 4n+1
      next;
    }
    die "oops";
  }
}

# absdy_bitwise() vs path
{
  my $path = Math::PlanePath::DragonMidpoint->new;
  my ($prev_x, $prev_y) = $path->n_to_xy (0);
  my $bad = 0;
  foreach my $n (0 .. 0x2FFF) {
    my ($x, $y) = $path->n_to_xy ($n);
    my ($nx, $ny) = $path->n_to_xy ($n+1);
    my $path_value = ($x == $nx
                      ? 1   # vertical
                      : 0); # horizontal

    my $a_value = absdy_bitwise($n);

    if ($path_value != $a_value) {
      MyTestHelpers::diag ("diff n=$n path=$path_value acalc=$a_value");
      MyTestHelpers::diag ("  xy=$x,$y  nxy=$nx,$ny");
      last if ++$bad > 10;
    }
  }
  ok ($bad, 0, "absdy_bitwise()");
}

sub absdy_bitwise {
  my ($n) = @_;
  return ($n & 1) ^ bit_above_lowest_zero($n);
}
sub bit_above_lowest_zero {
  my ($n) = @_;
  for (;;) {
    if (($n % 2) == 0) {
      last;
    }
    $n = int($n/2);
  }
  $n = int($n/2);
  return ($n % 2);
}

#------------------------------------------------------------------------------
exit 0;
