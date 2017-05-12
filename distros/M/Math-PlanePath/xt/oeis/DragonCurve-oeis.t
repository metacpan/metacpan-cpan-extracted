#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
plan tests => 29;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::DragonCurve;

# uncomment this to run the ### lines
# use Smart::Comments '###';


my $dragon = Math::PlanePath::DragonCurve->new;

sub is_square {
  my ($n) = @_;
  my $sqrt = int(sqrt($n));
  return $n == $sqrt*$sqrt;
}


#------------------------------------------------------------------------------
# A227741 permutation of the integers,
#         each dir many integers in reverse order

MyOEIS::compare_values
  (anum => 'A227741',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'LSR');
     my $upto = 1;
     my $dir = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $dir += $value;
       push @got, reverse $upto .. $upto+$dir-1;
       $upto += $dir;
     }
     $#got = $count-1;
     return \@got;
   });

   FORMULA    

# A227742 permutation fixed point
#
# middle of each odd dir
# turn +/-1 so dir alternately even,odd
# so per Antti Karttunen  A173318(2*(n-1)) + (1/2)*(1 + A005811(2n-1))
#
MyOEIS::compare_values
  (anum => 'A227742',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'LSR');
     my $upto = 1;
     my $dir = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $dir += $value;
       if ($dir %2) {
         push @got, $upto + ($dir-1)/2;
       }         
       $upto += $dir;
     }
     $#got = $count-1;
     return \@got;
   });


#------------------------------------------------------------------------------
# A164910 - dragon 1 + cumulative turn +/-1, partial sums of that cumulative
#   partial sums A088748
#   A001792 = (n+2)*2^(n-1)
# a(4) = 8   = 4*2^1
# a(8) = 20  = 5*2^2
# a(16)= 48  = 6*2^3
# a(32)= 112 = 7*2^4
MyOEIS::compare_values
  (anum => 'A164910',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'LSR');
     my $cumulative = 1;
     my $partial_sum = $cumulative;
     while (@got < $count) {
       push @got, $partial_sum;
       my ($i, $value) = $seq->next;
       $cumulative += $value;
       $partial_sum += $cumulative;
     }
     return \@got;
   });

# A173318 - dragon cumulative turn +/-1, partial sums of that cumulative
MyOEIS::compare_values
  (anum => 'A173318',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'LSR');
     my $cumulative = 0;
     my $partial_sum = $cumulative;
     while (@got < $count) {
       push @got, $partial_sum;
       my ($i, $value) = $seq->next;
       $cumulative += $value;
       $partial_sum += $cumulative;
     }
     return \@got;
   });

# A227744 squares among A173318 dragon dir cumulative
MyOEIS::compare_values
  (anum => 'A227744',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'LSR');
     my $cumulative = 0;
     my $partial_sum = $cumulative;
     while (@got < $count) {
       if (is_square($partial_sum)) {
         push @got, $partial_sum;
       }
       my ($i, $value) = $seq->next;
       $cumulative += $value;
       $partial_sum += $cumulative;
     }
     return \@got;
   });
# A227743 indexes of squares among A173318 dragon dir cumulative
MyOEIS::compare_values
  (anum => 'A227743',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'LSR');
     my $cumulative = 0;
     my $partial_sum = $cumulative;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $cumulative += $value;
       $partial_sum += $cumulative;
       if (is_square($partial_sum)) {
         push @got, $i;
       }
     }
     return \@got;
   });
# A227745 sqrts of squares among A173318 dragon dir cumulative
MyOEIS::compare_values
  (anum => 'A227745',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'LSR');
     my $cumulative = 0;
     my $partial_sum = $cumulative;
     while (@got < $count) {
       if (is_square($partial_sum)) {
         push @got, sqrt($partial_sum);
       }
       my ($i, $value) = $seq->next;
       $cumulative += $value;
       $partial_sum += $cumulative;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A005811 -- total rotation, count runs of bits in binary
#
MyOEIS::compare_values
  (anum => 'A005811',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'LSR');
     my $cumulative = 0;
     while (@got < $count) {
       push @got, $cumulative;
       my ($i, $value) = $seq->next;
       $cumulative += $value;
     }
     return \@got;
   });

# A136004 total turn + 4
MyOEIS::compare_values
  (anum => 'A136004',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'LSR');
     my $cumulative = 4;
     while (@got < $count) {
       push @got, $cumulative;
       my ($i, $value) = $seq->next;
       $cumulative += $value;
     }
     return \@got;
   });

# A037834 - dragon cumulative turn +/-1
#   -1 + sum i=1 to n  turn(n)
#
MyOEIS::compare_values
  (anum => 'A037834',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'LSR');
     my $cumulative = -1;  # sum - 1
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $cumulative += $value;
       push @got, $cumulative;
     }
     return \@got;
   });

# A088748 - dragon cumulative turn +/-1
#   1 + sum i=1 to n  turn(n)
#
MyOEIS::compare_values
  (anum => 'A088748',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'LSR');
     my $cumulative = 1;  # sum + 1
     while (@got < $count) {
       push @got, $cumulative;
       my ($i, $value) = $seq->next;
       $cumulative += $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# Skd num segments in directions to level k

foreach my $elem ([ 'A038503', 0, [1] ],
                  [ 'A038504', 1, [0] ],
                  [ 'A038505', 2, []  ],
                  [ 'A000749', 3, [0] ]) {
  my ($anum, $want_dir4, $initial, $skip) = @$elem;
  MyOEIS::compare_values
      (anum => $anum,
       max_count => 5,
       name => "dir=$want_dir4",
       func => sub {
         my ($count) = @_;
         my @got = @$initial;
         require Math::NumSeq::PlanePathDelta;
         my $seq = Math::NumSeq::PlanePathDelta->new(planepath_object=>$dragon,
                                                     delta_type => 'Dir4');
         my $target = 2;
         my $total = 0;
         while (@got < $count) {
           my ($i, $value) = $seq->next;
           if ($i == $target) {
             push @got, $total;
             $target *= 2;
           }
           $total += ($value == $want_dir4);
         }
         return \@got;
       });
}


#------------------------------------------------------------------------------
# A268411 - directions of horizontals, 0=East, 1=West

MyOEIS::compare_values
  (anum => 'A268411',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathDelta;
     my $seq = Math::NumSeq::PlanePathDelta->new(planepath_object=>$dragon,
                                                 delta_type => 'Dir4');
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value/2;
       $seq->next; # skip odd N
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A255070 - TurnsR num right turns 1 to N

MyOEIS::compare_values
  (anum => 'A255070',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Right');
     my $total = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $total += $value;
       push @got, $total;
     }
     return \@got;
   });

# A236840 - 2*TurnsR num right turns 1 to N
MyOEIS::compare_values
  (anum => 'A236840',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Right');
     my $total = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $total += $value;
       push @got, 2*$total;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A090678 - N not start of a turn run, so where turn same as previous

MyOEIS::compare_values
  (anum => 'A090678',
   func => sub {
     my ($count) = @_;
     my @got = (1,1);
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'LSR');
     (undef, my $prev_value) = $seq->next;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value == $prev_value ? 1 : 0;
       $prev_value = $value;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A106836 - N steps between right turns
# with a first term included so start $prev_i=0

MyOEIS::compare_values
  (anum => 'A106836',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Right');
     my $prev_i = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       next unless $value;
       if (defined $prev_i) { push @got, $i - $prev_i; }
       $prev_i = $i;
     }
     return \@got;
   });

# A088742 - N steps between left turns
# with a first term included so start $prev_i=0

MyOEIS::compare_values
  (anum => 'A088742',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Left');
     my $prev_i = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       next unless $value;
       if (defined $prev_i) { push @got, $i - $prev_i; }
       $prev_i = $i;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# Ba2 boundary length of arms=2 around whole of level k

# FIXME: Neither values nor diff are A052537 it seems, what was this mean to be?
#                                 *
#                                 |
# 3        5---*   4      *   *---*---*
# |            |   |      |   |   |   |
# o---2        o---*      *---*   o---*
#  len=4    k=2 len=8       k=3 len=14
#
# MyOEIS::compare_values
#   (anum => 'A052537',
#    max_value => 100,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      my $path = Math::PlanePath::DragonCurve->new (arms => 2);
#      my $k = 0;
#      my $prev = MyOEIS::path_boundary_length ($path, 2*2**$k + 1);
#      for ($k++; @got < $count; $k++) {
#        my $len = MyOEIS::path_boundary_length ($path, 2*2**$k + 1);
#        my $diff = $len - $prev;
#        push @got, $diff;
#        $prev = $len;
#      }
#      return \@got;
#    });

#------------------------------------------------------------------------------
# A091067 -- N positions of right turns
MyOEIS::compare_values
  (anum => 'A091067',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Right');
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value) {
         push @got, $i;
       }
     }
     return \@got;
   });

# A255068 -- N positions where next turn right
MyOEIS::compare_values
  (anum => 'A255068',
   name => 'N where next turn right',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Right');
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value) {
         push @got, $i-1;
       }
     }
     return \@got;
   });

# A060833 -- N positions where previous turn right
MyOEIS::compare_values
  (anum => 'A060833',
   name => 'N where previous turn right',
   func => sub {
     my ($count) = @_;
     my @got = (1);        # extra initial 1
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Right');
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value) {
         push @got, $i+1;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A091072 -- N positions of left turns

MyOEIS::compare_values
  (anum => 'A091072',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Left');
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A099545 -- turn 1=left, 3=right

MyOEIS::compare_values
  (anum => 'A099545',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Left');
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value ? 1 : 3;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003476 Daykin and Tucker alpha[n]
#   = RQ squares on right boundary, OFFSET=1 values 1, 2, 3, 5
#   = S single points N=0 to N=2^(k-1) inclusive, with initial 1 for k=-1 one point
#
#                     *
#                     |
#   *---*         *---*
#
#   k=0           k=1
#   singles=2     singles=3
#
#

MyOEIS::compare_values
  (anum => 'A003476',
   max_value => 10000,
   func => sub {
     my ($count) = @_;
     my @got = (1);
     for (my $k = 0; @got < $count; $k++) {
       push @got, MyOEIS::path_n_to_singles ($dragon, 2**$k);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A121238 - (-1)^(1+n+A088585(n)) is 1=left,-1=right, extra initial 1
# A088585 bisection or partial sums of A088567=non-squashing partitions
#           = A088575+1
# A088575 bisection of A088567

# A088567 a(0)=1, a(1)=1;
#   for m >= 1, a(2m)   = a(2m-1) + a(m) - 1,
#               a(2m+1) = a(2m) + 1
# A090678 = A088567 mod 2.

MyOEIS::compare_values
  (anum => 'A121238',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Left');
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value ? 1 : -1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A166242 - turn cumulative doubling/halving, is 2^(total turn)

MyOEIS::compare_values
  (anum => 'A166242',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Left');
     my $cumulative = 1;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value) {
         $cumulative *= 2;
       } else {
         $cumulative /= 2;
       }
       push @got, $cumulative;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A112347 - Kronecker -1/n is 1=left,-1=right, extra initial 0

MyOEIS::compare_values
  (anum => 'A112347',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Left');
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value ? 1 : -1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A014710 -- turn 2=left, 1=right

MyOEIS::compare_values
  (anum => 'A014710',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Left');
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value+1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A014709 -- turn 1=left, 2=right

MyOEIS::compare_values
  (anum => 'A014709',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Right');
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value+1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A014577 -- turn 1=left, 0=right, starting from 1
#
# cf A059125 is almost but not quite the same, the 8,24,or some such entries
# differ

MyOEIS::compare_values
  (anum => 'A014577',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Left');
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A014707 -- turn 0=left, 1=right, starting from 1

MyOEIS::compare_values
  (anum => 'A014707',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Right');
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A088431 - dragon turns run lengths

MyOEIS::compare_values
  (anum => 'A088431',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Right');
     my ($i, $prev) = $seq->next;
     my $run = 1; # count for initial $prev_turn
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == $prev) {
         $run++;
       } else {
         push @got, $run;
         $run = 1; # count for new $turn value
       }
       $prev = $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A007400 - 2 * run lengths, extra initial 0,1

# cf A007400 cont frac 1/2^1 + 1/2^2 + 1/2^4 + 1/2^8 + ... 1/2^(2^n)
#            = 0.8164215090218931...
#    2,4,6 values
#    a(0)=0,
#    a(1)=1,
#    a(2)=4,
#    a(8n) = a(8n+3) = 2,
#    a(8n+4) = a(8n+7) = a(16n+5) = a(16n+14) = 4,
#    a(16n+6) = a(16n+13) = 6,
#    a(8n+1) = a(4n+1),
#    a(8n+2) = a(4n+2)


MyOEIS::compare_values
  (anum => 'A007400',
   func => sub {
     my ($count) = @_;
     my @got = (0,1);
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Right');
     my ($i, $prev) = $seq->next;
     my $run = 1; # count for initial $prev_turn
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == $prev) {
         $run++;
       } else {
         push @got, 2 * $run;
         $run = 1; # count for new $turn value
       }
       $prev = $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003460 -- turn 1=left,0=right packed as octal high to low, in 2^n levels

MyOEIS::compare_values
  (anum => 'A003460',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::BigInt;
     my $bits = Math::BigInt->new(0);
     my $target_n_level = 2;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Left');
     for (my $n = 1; @got < $count; $n++) {
       if ($n >= $target_n_level) {  # not including n=2^level point itself
         my $octal = $bits->as_oct;  # new enough Math::BigInt
         $octal =~ s/^0+//;  # strip leading "0"
         push @got, Math::BigInt->new("$octal");
         $target_n_level *= 2;
       }
       my ($i, $value) = $seq->next;
       $bits = 2*$bits + $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A082410 -- complement reversal, is turn 1=left, 0=right

MyOEIS::compare_values
  (anum => 'A082410',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object=>$dragon,
                                                turn_type => 'Left');
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value; # 1=left,0=right
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A126937 -- points numbered as SquareSpiral, starting N=0

MyOEIS::compare_values
  (anum => 'A126937',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::SquareSpiral;
     my $square  = Math::PlanePath::SquareSpiral->new (n_start => 0);
     my @got;
     for (my $n = $dragon->n_start; @got < $count; $n++) {
       my ($x, $y) = $dragon->n_to_xy ($n);
       my $square_n = $square->xy_to_n ($x, -$y);
       push @got, $square_n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A077949 join area increments, ie. first differences

MyOEIS::compare_values
  (anum => 'A077949',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     my $prev = 0;
     for (my $k = 3; @got < $count; $k++) {
       my $join_area = $dragon->_UNDOCUMENTED_level_to_enclosed_area_join($k);
       push @got, $join_area - $prev;
       $prev = $join_area;
     }
     return \@got;
   });

# A003479 join area
MyOEIS::compare_values
  (anum => 'A003479',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 3; @got < $count; $k++) {
       push @got, $dragon->_UNDOCUMENTED_level_to_enclosed_area_join($k);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A003478 enclosed area increment, ie. first differences

MyOEIS::compare_values
  (anum => 'A003478',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     my $prev_area = 0;
     for (my $k = 4; @got < $count; $k++) {
       my $area = MyOEIS::path_enclosed_area ($dragon, 2**$k);
       push @got, $area - $prev_area;
       $prev_area = $area;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003230 enclosed area to N <= 2^k

MyOEIS::compare_values
  (anum => 'A003230',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 4; @got < $count; $k++) {
       push @got, MyOEIS::path_enclosed_area ($dragon, 2**$k);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A164395 single points N=0 to N=2^k-1 inclusive, for k=4 up
#   is count binary with no substrings equal to 0001 or 0101

MyOEIS::compare_values
  (anum => 'A164395',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 4; @got < $count; $k++) {
       push @got, MyOEIS::path_n_to_singles ($dragon, 2**$k - 1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A227036 boundary length N <= 2^k

MyOEIS::compare_values
  (anum => 'A227036',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       push @got, MyOEIS::path_boundary_length ($dragon, 2**$k);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A038189 -- bit above lowest 1, is 0=left,1=right

MyOEIS::compare_values
  (anum => 'A038189',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'DragonCurve',
                                                 turn_type => 'Right');
     my @got = (0);  # extra initial 0
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

# A089013=A038189 but initial extra 1
MyOEIS::compare_values
  (anum => 'A089013',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'DragonCurve',
                                                 turn_type => 'Right');
     my @got = (1);  # extra initial 1
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
