#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2017, 2019 Kevin Ryde

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
use Math::BigInt try => 'GMP';
use Test;
plan tests => 17;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::CCurve;
use Math::NumSeq::PlanePathTurn;

# uncomment this to run the ### lines
# use Smart::Comments '###';


my $path = Math::PlanePath::CCurve->new;

sub right_boundary {
  my ($n_end) = @_;
  return MyOEIS::path_boundary_length ($path, $n_end, side => 'right');
}
use Memoize;
Memoize::memoize('right_boundary');


#------------------------------------------------------------------------------
# A036554 - positions ending odd 0 bits is where turn straight or reverse
MyOEIS::compare_values
  (anum => 'A036554',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'CCurve',
                                                 turn_type => 'Straight');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value) { push @got, $i; }   # N where straight
     }
     return \@got;
   });

# A003159 - positions ending even 0 bits is where turn either left or right,
# ie. not straight or reverse
MyOEIS::compare_values
  (anum => 'A003159',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'CCurve',
                                                 turn_type => 'NotStraight');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value) { push @got, $i; }   # N where not straight
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A096268 - morphism turn 1=straight,0=not-straight
#   but OFFSET=0 is turn at N=1, so "next turn"

MyOEIS::compare_values
  (anum => 'A096268',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'CCurve',
                                                 turn_type => 'Straight');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A096268},
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, count_low_1_bits($n) % 2;
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => q{A096268},
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, count_low_0_bits($n+1) % 2;
     }
     return \@got;
   });

sub count_low_1_bits {
  my ($n) = @_;
  my $count = 0;
  while ($n % 2) {
    $count++;
    $n = int($n/2);
  }
  return $count;
}
sub count_low_0_bits {
  my ($n) = @_;
  if ($n == 0) { die; }
  my $count = 0;
  until ($n % 2) {
    $count++;
    $n /= 2;
  }
  return $count;
}

#------------------------------------------------------------------------------
# A035263 - morphism turn 0=straight, 1=not-straight

MyOEIS::compare_values
  (anum => 'A035263',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'CCurve',
                                                 turn_type => 'NotStraight');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A035263}, # second check
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       push @got, (count_low_0_bits($n) + 1) % 2;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A027383 right boundary differences
# cf
# CCurve right boundary diffs even terms
# 6,14,30,62,126
# A000918 2^n - 2.
# CCurve right boundary diffs odd terms
# 10,22,46,94,190
# A033484 3*2^n - 2.

MyOEIS::compare_values
  (anum => 'A027383',
   max_value => 5000,
   func => sub {
     my ($count) = @_;
     my @got = (1);
     for (my $k = 1; @got < $count; $k++) {
       my $b1 = right_boundary(2**$k);
       my $b2 = right_boundary(2**($k+1));
       push @got, $b2 - $b1;
     }
     return \@got;
   });

# A131064 right boundary odd powers, extra initial 1
MyOEIS::compare_values
  (anum => 'A131064',
   max_value => 5000,
   func => sub {
     my ($count) = @_;
     my @got = (1);
     for (my $k = 1; @got < $count; $k++) {
       my $boundary = right_boundary(2**(2*$k-1));  # 1,3,5,..
       push @got, $boundary;
       ### at: "k=$k $boundary"
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A038503 etc counts of segments in direction

foreach my $elem ([0, 'A038503', 0],
                  [1, 'A038504', 0],
                  [2, 'A038505', 1],
                  [3, 'A000749', 0]) {
  my ($dir, $anum, $initial_k) = @$elem;
  MyOEIS::compare_values
      (anum => $anum,
       name => "segments in direction dir=$dir",
       max_value => 10_000,
       func => sub {
         my ($count) = @_;
         require Math::NumSeq::PlanePathDelta;
         my $seq = Math::NumSeq::PlanePathDelta->new (planepath => 'CCurve',
                                                      delta_type => 'Dir4');
         my $total = 0;
         my $k = $initial_k;
         my $n_end = 2**$k;
         my @got;
         for (;;) {
           my ($i,$value) = $seq->next;
           if ($i >= $n_end) {   # $i now in next level
             push @got, $total;
             last if @got >= $count;
             $k++;
             $n_end = 2**$k;
           }
           $total += ($value==$dir);
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A000120 - count 1 bits total turn is direction

MyOEIS::compare_values
  (anum => 'A000120',
   fixup => sub {
     my ($bvalues) = @_;
     @$bvalues = map {$_ % 4} @$bvalues;
   },
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathDelta;
     my $seq = Math::NumSeq::PlanePathDelta->new (planepath => 'CCurve',
                                                  delta_type => 'Dir4');
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A007814 - count low 0s, is turn right - 1

MyOEIS::compare_values
  (anum => 'A007814',
   fixup => sub {
     my ($bvalues) = @_;
     @$bvalues = map {$_ % 4} @$bvalues;
   },
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq = Math::NumSeq::PlanePathTurn->new
       (planepath => 'CCurve',
        turn_type => 'Turn4');   # 0,1,2,3 leftward
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, (1-$value) % 4;  # negate to right
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A104488 -- num Hamiltonian groups
# No, different at n=67 and more
#
# MyOEIS::compare_values
#   (anum => 'A104488',
#    func => sub {
#      my ($count) = @_;
#      require Math::NumSeq::PlanePathTurn;
#      my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'CCurve',
#                                                  turn_type => 'Right');
#      my @got = (0,0,0,0);;
#      while (@got < $count) {
#        my ($i,$value) = $seq->next;
#        push @got, $value;
#      }
#      return \@got;
#    });

#------------------------------------------------------------------------------
# A146559 = (i+1)^k is X+iY at N=2^k
# A009545 = Im

# A146559   X at N=2^k, being Re((i+1)^k)
# A009545   Y at N=2^k, being Im((i+1)^k)

MyOEIS::compare_values
  (anum => 'A146559',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = Math::BigInt->new(1); @got < $count; $n *= 2) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x;
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => 'A009545',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = Math::BigInt->new(1); @got < $count; $n *= 2) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
