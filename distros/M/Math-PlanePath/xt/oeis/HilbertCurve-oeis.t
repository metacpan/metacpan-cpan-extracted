#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2017, 2018 Kevin Ryde

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
use Test;
plan tests => 46;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::Base::Digits
  'bit_split_lowtohigh';

use Math::PlanePath::HilbertCurve;
my $hilbert  = Math::PlanePath::HilbertCurve->new;

use Math::PlanePath::ZOrderCurve;
my $zorder   = Math::PlanePath::ZOrderCurve->new;

use Math::PlanePath::Diagonals;

#------------------------------------------------------------------------------

sub zorder_perm {
  my ($n) = @_;
  my ($x, $y) = $zorder->n_to_xy ($n);
  return $hilbert->xy_to_n ($x, $y);
}
sub zorder_perm_inverse {
  my ($n) = @_;
  my ($x, $y) = $hilbert->n_to_xy ($n);
  return $zorder->xy_to_n ($x, $y);
}
sub zorder_perm_rep {
  my ($n, $reps) = @_;
  foreach (1 .. $reps) {
    my ($x, $y) = $zorder->n_to_xy ($n);
    $n = $hilbert->xy_to_n ($x, $y);
  }
  return $n;
}
sub zorder_cycle_length {
  my ($n) = @_;
  my $count = 1;
  my $p = $n;
  for (;;) {
    $p = zorder_perm($p);
    if ($p == $n) {
      last;
    }
    $count++;
  }
  return $count;
}
sub zorder_is_2cycle {
  my ($n) = @_;
  my $p1 = zorder_perm($n);
  if ($p1 == $n) { return 0; }
  my $p2 = zorder_perm($p1);
  return ($p2 == $n);
}
sub zorder_is_3cycle {
  my ($n) = @_;
  my $p1 = zorder_perm($n);
  if ($p1 == $n) { return 0; }
  my $p2 = zorder_perm($p1);
  if ($p2 == $n) { return 0; }
  my $p3 = zorder_perm($p2);
  return ($p3 == $n);
}

#------------------------------------------------------------------------------
# A147600 - num fixed points in 4^k blocks

MyOEIS::compare_values
  (anum => 'A147600',
   max_count => 9,
   func => sub {
     my ($bvalues_count) = @_;
     my @got;
     my $target = 4;
     my $count = 0;
     for (my $n = 1; @got < $bvalues_count; $n++) {
       if ($n >= $target) {
         push @got, $count;
         $count = 0;
         $target *= 4;
       }
       if ($n == zorder_perm($n)) {
         $count++;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163894 - first i for which (perm^n)[i] != i

MyOEIS::compare_values
  (anum => 'A163894',
   max_count => 200,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, A163894_perm_n_not($n);
     }
     return \@got;
   });

sub A163894_perm_n_not {
  my ($n) = @_;
  if ($n == 0) {
    return 0;
  }
  for (my $i = 0; ; $i++) {
    my $p = zorder_perm_rep ($i, $n);
    if ($p != $i) {
      return $i;
    }
  }
}

#------------------------------------------------------------------------------
# A083885 etc counts of segments in direction

foreach my $elem ([0, 'A083885', 0],
                  # [1, '', 0],
                  # [2, '', 1],
                  # [3, '', 0]
                 ) {
  my ($dir, $anum, $initial_k) = @$elem;
  MyOEIS::compare_values
      (anum => $anum,
       max_value => 10_000,
       func => sub {
         my ($count) = @_;
         my @got;
         my $n = $hilbert->n_start;
         my $total = 0;
         my $k = $initial_k;
         while (@got < $count) {
           my $n_end = 4**$k;
           for ( ; $n < $n_end; $n++) {
             $total += (dxdy_to_dir4($hilbert->n_to_dxdy($n)) == $dir);
           }
           push @got, $total;
           $k++;
         }
         return \@got;
       });
}

# return 0,1,2,3, with Y reckoned increasing upwards
sub dxdy_to_dir4 {
  my ($dx, $dy) = @_;
  if ($dx > 0) { return 0; }  # east
  if ($dx < 0) { return 2; }  # west
  if ($dy > 0) { return 1; }  # north
  if ($dy < 0) { return 3; }  # south
}

#------------------------------------------------------------------------------
# A163541 -- absolute direction transpose 0=east, 1=south, 2=west, 3=north

MyOEIS::compare_values
  (anum => 'A163541',
   name => 'absolute direction transpose',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $hilbert->n_start; @got < $count; $n++) {
       my ($dx, $dy) = $hilbert->n_to_dxdy ($n);
       ($dx,$dy) = ($dy,$dx);   # transpose
       push @got, MyOEIS::dxdy_to_direction ($dx, $dy);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163895 - position where A163894 is a new high

MyOEIS::compare_values
  (anum => 'A163895',
   max_count => 8,
   func => sub {
     my ($count) = @_;
     my @got;
     my $high = -1;
     for (my $n = 0; @got < $count; $n++) {
       my $value = A163894_perm_n_not($n);
       if ($value > $high) {
         $high = $value;
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A139351 - HammingDist(X,Y) = count 1-bits at even bit positions in N

MyOEIS::compare_values
  (name => 'HammingDist(X,Y)',
   anum => 'A139351',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my ($x, $y) = $hilbert->n_to_xy($n);
       push @got, HammingDist($x,$y);
     }
     return \@got;
   });
MyOEIS::compare_values
  (name => 'count 1-bits at even bit positions',
   anum => qq{A139351},
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my @nbits = bit_split_lowtohigh($n);
       my $count = 0;
       for (my $i = 0; $i <= $#nbits; $i+=2) {
         $count += $nbits[$i];
       }
       push @got, $count;
     }
     return \@got;
   });

sub HammingDist {
  my ($x,$y) = @_;
  my @xbits = bit_split_lowtohigh($x);
  my @ybits = bit_split_lowtohigh($y);
  my $ret = 0;
  while (@xbits || @ybits) {
    $ret += (shift @xbits ? 1 : 0) ^ (shift @ybits ? 1 : 0);
  }
  return $ret;
}

#------------------------------------------------------------------------------
# A163893 - first diffs of positions where cycle length some new unseen value

MyOEIS::compare_values
  (anum => 'A163893',
   name => 'cycle length by N',
   max_count => 20,
   func => sub {
     my ($count) = @_;
     my @got;
     my %seen = (1 => 1);
     my $prev = 0;
     for (my $n = 0; @got < $count; $n++) {
       my $len = zorder_cycle_length($n);
       if (! $seen{$len}) {
         push @got, $n-$prev;
         $prev = $n;
         $seen{$len} = 1;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163896 - value where A163894 is a new high

MyOEIS::compare_values
  (anum => 'A163896',
   max_count => 8,
   func => sub {
     my ($count) = @_;
     my @got;
     my $high = -1;
     for (my $n = 0; @got < $count; $n++) {
       my $value = A163894_perm_n_not($n);
       if ($value > $high) {
         $high = $value;
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163900 - squared distance between Hilbert and Z order

MyOEIS::compare_values
  (name => 'squared distance between Hilbert and ZOrder',
   anum => 'A163900',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my ($hx, $hy) = $hilbert->n_to_xy ($n);
       my ($zx, $zy) = $zorder->n_to_xy ($n);
       my $dx = $hx - $zx;
       my $dy = $hy - $zy;
       push @got, $dx**2 + $dy**2;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163891 - positions where cycle length some new previously unseen value
#
# len: 1, 1, 2, 2, 6, 3, 3, 6, 6, 6, 3, 3, 6, 3, 6, 3, 1, 3, 3, 3, 1, 1, 2, 2,
#      ^
# 91:  0     2     4  5

MyOEIS::compare_values
  (name => "cycle length by N",
   anum => 'A163891',
   max_count => 20,
   func => sub {
     my ($count) = @_;
     my @got;
     my %seen;
     for (my $n = 0; @got < $count; $n++) {
       my $len = zorder_cycle_length($n);
       if (! $seen{$len}) {
         push @got, $n;
         $seen{$len} = 1;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A165466 -- dx^2+dy^2 of Hilbert->Peano transposed
MyOEIS::compare_values
  (anum => 'A165466',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::PeanoCurve;
     my $peano  = Math::PlanePath::PeanoCurve->new;
     my @got;
     for (my $n = $hilbert->n_start; @got < $count; $n++) {
       my ($hx,$hy) = $hilbert->n_to_xy($n);
       my ($px,$py) = $peano->n_to_xy($n);
       ($px,$py) = ($py,$px);
       push @got, ($px-$hx)**2 + ($py-$hy)**2;
     }
     return \@got;
   });

# A165464 -- dx^2+dy^2 of Hilbert->Peano
MyOEIS::compare_values
  (anum => 'A165464',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::PeanoCurve;
     my $peano  = Math::PlanePath::PeanoCurve->new;
     my @got;
     for (my $n = $hilbert->n_start; @got < $count; $n++) {
       my ($hx,$hy) = $hilbert->n_to_xy($n);
       my ($px,$py) = $peano->n_to_xy($n);
       push @got, ($px-$hx)**2 + ($py-$hy)**2;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A165467 -- N where Hilbert and Peano same X,Y
MyOEIS::compare_values
  (anum => 'A165467',
   max_value => 100000,
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::PeanoCurve;
     my $peano  = Math::PlanePath::PeanoCurve->new;
     my @got;
     for (my $n = $hilbert->n_start; @got < $count; $n++) {
       my ($hx,$hy) = $hilbert->n_to_xy($n);
       my ($px,$py) = $peano->n_to_xy($n);
       if ($hx == $py && $hy == $px) {
         push @got, $n;
       }
     }
     return \@got;
   });

# A165465 -- N where Hilbert and Peano same X,Y
MyOEIS::compare_values
  (anum => 'A165465',
   max_value => 100000,
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::PeanoCurve;
     my $peano  = Math::PlanePath::PeanoCurve->new;
     my @got;
     for (my $n = $hilbert->n_start; @got < $count; $n++) {
       my ($hx,$hy) = $hilbert->n_to_xy($n);
       my ($px,$py) = $peano->n_to_xy($n);
       if ($hx == $px && $hy == $py) {
         push @got, $n;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A163538 -- dX
# extra first entry for N=0 no change

MyOEIS::compare_values
  (anum => 'A163538',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $n = $hilbert->n_start; @got < $count; $n++) {
       my ($dx, $dy) = $hilbert->n_to_dxdy ($n);
       push @got, $dx;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163539 -- dY
# extra first entry for N=0 no change

MyOEIS::compare_values
  (anum => 'A163539',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $n = $hilbert->n_start; @got < $count; $n++) {
       my ($dx, $dy) = $hilbert->n_to_dxdy ($n);
       push @got, $dy;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A166041 - N in Peano order

MyOEIS::compare_values
  (anum => 'A166041',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::PeanoCurve;
     my $peano = Math::PlanePath::PeanoCurve->new;
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($x, $y) = $peano->n_to_xy($n);
       push @got, $hilbert->xy_to_n ($x, $y);
     }
     return \@got;
   });

# inverse Peano in Hilbert order
MyOEIS::compare_values
  (anum => 'A166042',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::PeanoCurve;
     my $peano = Math::PlanePath::PeanoCurve->new;
     my @got;
     for (my $n = $hilbert->n_start; @got < $count; $n++) {
       my ($x, $y) = $hilbert->n_to_xy($n);
       push @got, $peano->xy_to_n ($x, $y);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A163540 -- absolute direction 0=east, 1=south, 2=west, 3=north
# Y coordinates reckoned down the page, so south is Y increasing

MyOEIS::compare_values
  (anum => 'A163540',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $hilbert->n_start; @got < $count; $n++) {
       my ($dx, $dy) = $hilbert->n_to_dxdy ($n);
       push @got, MyOEIS::dxdy_to_direction ($dx, $dy);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163909 - num 3-cycles in 4^k blocks, even k only

MyOEIS::compare_values
  (anum => 'A163909',
   max_count => 5,
   func => sub {
     my ($bvalues_count) = @_;
     my @got;
     my $target = 1;
     my $target_even = 1;
     my $count = 0;
     my @seen;
     for (my $n = 0; @got < $bvalues_count; $n++) {
       if ($n >= $target) {
         if ($target_even) {
           push @got, $count;
         }
         $target_even ^= 1;
         $count = 0;
         $target *= 4;
         @seen = ();
         $#seen = $target; # pre-extend
       }

       unless ($seen[$n]) {
         my $p1 = zorder_perm($n);
         next if $p1 == $n; # a fixed point
         my $p2 = zorder_perm($p1);
         next if $p2 == $n; # a 2-cycle
         my $p3 = zorder_perm($p2);
         next unless $p3 == $n; # not a 3-cycle
         $count++;
         $seen[$n] = 1;
         $seen[$p1] = 1;
         $seen[$p2] = 1;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163914 - num 3-cycles in 4^k blocks

MyOEIS::compare_values
  (anum => 'A163914',
   max_count => 8,
   func => sub {
     my ($bvalues_count) = @_;
     my @got;
     my $target = 1;
     my $count = 0;
     my @seen;
     for (my $n = 0; @got < $bvalues_count; $n++) {
       if ($n >= $target) {
         push @got, $count;
         $count = 0;
         $target *= 4;
         @seen = ();
         $#seen = $target; # pre-extend
       }

       unless ($seen[$n]) {
         my $p1 = zorder_perm($n);
         next if $p1 == $n; # a fixed point
         my $p2 = zorder_perm($p1);
         next if $p2 == $n; # a 2-cycle
         my $p3 = zorder_perm($p2);
         next unless $p3 == $n; # not a 3-cycle
         $count++;
         $seen[$n] = 1;
         $seen[$p1] = 1;
         $seen[$p2] = 1;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163908 - perm twice, by diagonals, inverse

MyOEIS::compare_values
  (anum => 'A163908',
   func => sub {
     my ($count) = @_;
     my @got;
     my $diagonal = Math::PlanePath::Diagonals->new
       (direction => 'up');   # from same axis as Hilbert

     for (my $n = 0; @got < $count; $n++) {
       my $nn = zorder_perm_inverse(zorder_perm_inverse($n));
       my ($x, $y) = $zorder->n_to_xy ($nn);
       my $dn = $diagonal->xy_to_n ($x, $y);
       push @got, $dn-1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163907 - perm twice, by diagonals

MyOEIS::compare_values
  (anum => 'A163907',
   func => sub {
     my ($count) = @_;
     my @got;
     my $diagonal = Math::PlanePath::Diagonals->new
       (direction => 'up');   # from same axis as Hilbert

     for (my $dn = $diagonal->n_start; @got < $count; $dn++) {
       my ($x, $y) = $diagonal->n_to_xy ($dn);
       my $n = $zorder->xy_to_n ($x, $y);
       push @got, zorder_perm(zorder_perm($n));
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163904 - cycle length by diagonals

MyOEIS::compare_values
  (anum => 'A163904',
   func => sub {
     my ($count) = @_;
     my @got;
     my $diagonal = Math::PlanePath::Diagonals->new
       (direction => 'up');   # from same axis as Hilbert

     for (my $dn = $diagonal->n_start; @got < $count; $dn++) {
       my ($x, $y) = $diagonal->n_to_xy ($dn);
       my $hn = $hilbert->xy_to_n ($x, $y);
       push @got, zorder_cycle_length($hn);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163890 - cycle length by N

MyOEIS::compare_values
  (anum => 'A163890',
   max_count => 10000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, zorder_cycle_length($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163912 - LCM of cycle lengths in 4^k blocks

MyOEIS::compare_values
  (anum => 'A163912',
   max_count => 6,
   func => sub {
     my ($count) = @_;
     my @got;
     my $target = 1;
     my $max = 0;
     my %lengths;
     for (my $n = 0; @got < $count; $n++) {
       if ($n >= $target) {
         push @got, lcm(keys %lengths);
         $target *= 4;
         %lengths = ();
       }
       $lengths{zorder_cycle_length($n)} = 1;
     }
     return \@got;
   });

use Math::PlanePath::GcdRationals;
sub lcm {
  my $lcm = 1;
  foreach my $n (@_) {
    my $gcd = Math::PlanePath::GcdRationals::_gcd($lcm,$n);
    $lcm = $lcm * $n / $gcd;
  }
  return $lcm;
}

#------------------------------------------------------------------------------
# A163911 - max cycle in 4^k blocks

MyOEIS::compare_values
  (anum => 'A163911',
   max_count => 7,
   func => sub {
     my ($count) = @_;
     my @got;
     my $target = 1;
     my $max = 0;
     for (my $n = 0; @got < $count; $n++) {
       if ($n >= $target) {
         push @got, $max;
         $max = 0;
         $target *= 4;
       }
       $max = max ($max, zorder_cycle_length($n));
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A163910 - num cycles in 4^k blocks

MyOEIS::compare_values
  (anum => 'A163910',
   max_count => 9,
   func => sub {
     my ($bvalues_count) = @_;
     my @got;
     my $target = 1;
     my $count = 0;
     my @seen;
     for (my $n = 0; @got < $bvalues_count; $n++) {
       if ($n >= $target) {
         push @got, $count;
         $count = 0;
         $target *= 4;
         @seen = ();
         $#seen = $target; # pre-extend
       }

       $count++;
       my $p = $n;
       for (;;) {
         $p = zorder_perm($p);
         if ($seen[$p]) {
           $count--;
           last;
         }
         $seen[$p] = 1;
         last if $p == $n;
       }
       $seen[$n] = 1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163355 - in Z order sequence

MyOEIS::compare_values
  (anum => 'A163355',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, zorder_perm($n);
     }
     return \@got;
   });

# A163356 - inverse
MyOEIS::compare_values
  (anum => 'A163356',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my ($x, $y) = $hilbert->n_to_xy ($n);
       push @got, $zorder->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A163905 - applied twice
MyOEIS::compare_values
  (anum => 'A163905',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, zorder_perm(zorder_perm($n));
     }
     return \@got;
   });

# A163915 - applied three times
# A163905 - applied twice
MyOEIS::compare_values
  (anum => 'A163915',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, zorder_perm(zorder_perm(zorder_perm($n)));
     }
     return \@got;
   });

# A163901 - fixed-point N values
MyOEIS::compare_values
  (anum => 'A163901',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       if (zorder_perm($n) == $n) {
         push @got, $n;
       }
     }
     return \@got;
   });

# A163902 - 2-cycle N values
MyOEIS::compare_values
  (anum => 'A163902',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       if (zorder_is_2cycle($n)) {
         push @got, $n;
       }
     }
     return \@got;
   });

# A163903 - 3-cycle N values
MyOEIS::compare_values
  (anum => 'A163903',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       if (zorder_is_3cycle($n)) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163357 - in diagonal sequence

MyOEIS::compare_values
  (anum => 'A163357',
   func => sub {
     my ($count) = @_;
     my @got;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down',
                                                     n_start => 0);
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($y, $x) = $diagonal->n_to_xy ($n);
       push @got, $hilbert->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A163358 - inverse
MyOEIS::compare_values
  (anum => 'A163358',
   func => sub {
     my ($count) = @_;
     my @got;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down',
                                                     n_start => 0);
     for (my $n = $hilbert->n_start; @got < $count; $n++) {
       my ($y, $x) = $hilbert->n_to_xy ($n);
       push @got, $diagonal->xy_to_n ($x, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163359 - in diagonal sequence, opp sides

MyOEIS::compare_values
  (anum => 'A163359',
   func => sub {
     my ($count) = @_;
     my @got;
     my $diagonal = Math::PlanePath::Diagonals->new
       (direction => 'down');  # from opposite side
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $hilbert->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A163360 - inverse
MyOEIS::compare_values
  (anum => 'A163360',
   func => sub {
     my ($count) = @_;
     my @got;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down',
                                                     n_start => 0);
     for (my $n = $hilbert->n_start; @got < $count; $n++) {
       my ($x, $y) = $hilbert->n_to_xy ($n);
       push @got, $diagonal->xy_to_n ($x, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163361 - diagonal sequence, one based, same side

MyOEIS::compare_values
  (anum => 'A163361',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $hilbert->xy_to_n ($x, $y) + 1; # 1-based Hilbert
     }
     return \@got;
   });

# A163362 - inverse
MyOEIS::compare_values
  (anum => 'A163362',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $n = $hilbert->n_start; @got < $count; $n++) {
       my ($x, $y) = $hilbert->n_to_xy ($n);
       push @got, $diagonal->xy_to_n ($x, $y); # 1-based Hilbert
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163363 - diagonal sequence, one based, opp sides

MyOEIS::compare_values
  (anum => 'A163363',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down');
     my @got;
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $hilbert->xy_to_n ($x, $y) + 1;
     }
     return \@got;
   });

# A163364 - inverse
MyOEIS::compare_values
  (anum => 'A163364',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down');
     my @got;
     for (my $n = $hilbert->n_start; @got < $count; $n++) {
       my ($x, $y) = $hilbert->n_to_xy ($n);
       push @got, $diagonal->xy_to_n ($x, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163365 - diagonal sums

MyOEIS::compare_values
  (anum => 'A163365',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $d = 0; @got < $count; $d++) {
       my $sum = 0;
       foreach my $x (0 .. $d) {
         my $y = $d - $x;
         $sum += $hilbert->xy_to_n ($x, $y);
       }
       push @got, $sum;
     }
     return \@got;
   });

# A163477 - diagonal sums divided by 4
MyOEIS::compare_values
  (anum => 'A163477',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $d = 0; @got < $count; $d++) {
       my $sum = 0;
       foreach my $x (0 .. $d) {
         my $y = $d - $x;
         $sum += $hilbert->xy_to_n ($x, $y);
       }
       push @got, int($sum/4);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
