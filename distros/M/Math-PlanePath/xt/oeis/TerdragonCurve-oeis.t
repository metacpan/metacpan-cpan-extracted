#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2020, 2021 Kevin Ryde

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
use Math::BigInt;
use Test;
plan tests => 47;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::TerdragonCurve;
use Math::NumSeq::PlanePathTurn;

# uncomment this to run the ### lines
# use Smart::Comments '###';


my $path = Math::PlanePath::TerdragonCurve->new;

sub ternary_digit_above_low_zeros {
  my ($n) = @_;
  if ($n == 0) {
    return 0;
  }
  while (($n % 3) == 0) {
    $n = int($n/3);
  }
  return ($n % 3);
}


#------------------------------------------------------------------------------
# A189674 - num left turns 1..N

MyOEIS::compare_values
  (anum => 'A189674',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Left');
     my $total = 0;
     my @got;
     for (my $n = $path->n_start + 1; @got < $count; $n++) {
       push @got, $total;
       $total += $seq->ith($n);
     }
     return \@got;
   });

# A189641 - num right turns 1..N
MyOEIS::compare_values
  (anum => 'A189641',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my $total = 0;
     my @got;
     for (my $n = $path->n_start + 1; @got < $count; $n++) {
       push @got, $total;
       $total += $seq->ith($n);
     }
     return \@got;
   });

# A189672 - num right turns 1..N, sans one initial 0
MyOEIS::compare_values
  (anum => 'A189672',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my $total = 0;
     my @got;
     for (my $n = $path->n_start + 1; @got < $count; $n++) {
       $total += $seq->ith($n);
       push @got, $total;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A133162 - 1 for each segment, 2 when right turn between

MyOEIS::compare_values
  (anum => 'A133162',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       push @got, 1;
       if ($seq->ith($n+1)) {
         push @got, 2;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A000001 -- (X-Y)/2 coordinate, at 60 degrees

# # not in OEIS: 0,1,0,1,0,0,-1,0,-1,0,-1,-1,-2,-2,-1,-1,-2,-2,-3,-2,-3,-2,-3,-3
# MyOEIS::compare_values
#   (anum => 'A000001',
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $n = 0; @got < $count; $n++) {
#        my ($x,$y) = $path->n_to_xy($n);
#        push @got, ($x-$y)/2;
#      }
#      return \@got;
#    });
#
# A000001 -- (X+Y)/2 coordinate, at 120 degrees
# # not in OEIS: 0,1,1,2,2,1,1,2,2,3,3,2,2,1,2,1,1,0,0,1,1,2,2,1,1,2,2,3,3,2,2,1
# MyOEIS::compare_values
#   (anum => 'A000001',
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $n = 0; @got < $count; $n++) {
#        my ($x,$y) = $path->n_to_xy($n);
#        push @got, ($x+$y)/2;
#      }
#      return \@got;
#    });
#
# # A000001 -- Y coordinate
# # not in OEIS: 0,0,1,1,2,1,2,2,3,3,4,3,4,3,3,2,3,2,3,3,4,4,5,4,5,5,6,6,7,6,7,6
# MyOEIS::compare_values
#   (anum => 'A000001',
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $n = 0; @got < $count; $n++) {
#        my ($x,$y) = $path->n_to_xy($n);
#        push @got, $y;
#      }
#      return \@got;
#    });


#------------------------------------------------------------------------------
# A005823 - N positions with net turn == 0, no ternary 1s
# A023692 through A023698
#           N positions where direction = 1 to 7, ternary num 1s

foreach my $elem (['A005823',0],
                  ['A023692',1],
                  ['A023693',2],
                  ['A023694',3],
                  ['A023695',4],
                  ['A023696',5],
                  ['A023697',6],
                  ['A023698',7]) {
  my ($anum, $want_dir) = @$elem;
  MyOEIS::compare_values
      (anum => $anum,
       func => sub {
         my ($count) = @_;
         my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                     turn_type => 'LSR');
         my $i = 0;
         my $dir = 0;
         my @got;
         while (@got < $count) {
           if ($dir == $want_dir) {
             push @got, $i;
           }
           $i++;
           my ($this_i, $value) = $seq->next;
           $i == $this_i or die;
           $dir += $value;
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A026141,A026171 - dTurnLeft step N positions of left turns

foreach my $anum ('A026141','A026171') {
  MyOEIS::compare_values
      (anum => $anum,
       name => "dTurnLeft $anum",
       func => sub {
         my ($count) = @_;
         my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                     turn_type => 'Left');
         my $prev = 0;
         my @got;
         while (@got < $count) {
           my ($i, $value) = $seq->next;
           if ($value == 1) {
             push @got, $i-$prev;
             $prev = $i;
           }
         }
         return \@got;
       });
}

# A026181,A131989 - dTurnRight step N positions of right turns
foreach my $anum ('A026181','A131989') {
  MyOEIS::compare_values
      (anum => $anum,
       name => "dTurnRight $anum",
       func => sub {
         my ($count) = @_;
         my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                     turn_type => 'Right');
         my $prev = 0;
         if ($anum eq 'A026181') { # skip one initial
           my $value;
           do {
             ($prev,$value) = $seq->next;
           } until ($value == 1);
         }
         my @got;
         while (@got < $count) {
           my ($i, $value) = $seq->next;
           if ($value == 1) {
             push @got, $i-$prev;
             $prev = $i;
           }
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A057682 level X
# A057083 level Y

foreach my $elem (['A057682', 1, 0, 0, [0,1]],  # X
                  ['A057083', 1, 1, 1, []   ],  # Y

                  ['A057681', 2, 0, 0, [1,1]],   # X arms=2
                  ['A103312', 2, 0, 0, [0,1,1]], # X arms=2
                  ['A057682', 2, 1, 0, [0]  ],   # Y arms=2

                  ['A057681', 3, 1, 0, [1]],     # Y arms=3
                  ['A103312', 3, 1, 0, [0,1]],   # Y arms=3
                 ) {
  my ($anum, $arms, $coord, $initial_level, $initial_got) = @$elem;
  my $path = Math::PlanePath::TerdragonCurve->new (arms => $arms);
  MyOEIS::compare_values
      (anum => $anum,
       name => "$anum arms=$arms",
       func => sub {
         my ($count) = @_;
         my @got = @$initial_got;
         for (my $k = $initial_level; @got < $count; $k++) {
           my ($n_lo,$n_hi) = $path->level_to_n_range(Math::BigInt->new($k));
           my @coords = $path->n_to_xy($n_hi);
           push @got, $coords[$coord];
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A092236 etc counts of segments in direction within level

foreach my $elem ([1, 'A057083', [],  1],
                  [0, 'A092236', [],  0],
                  [1, 'A135254', [0], 0],
                  [2, 'A133474', [0], 0]) {
  my ($dir, $anum, $initial_got, $offset_3k) = @$elem;
  MyOEIS::compare_values
      (anum => $anum,
       max_value => 8,
       func => sub {
         my ($count) = @_;
         my @got = @$initial_got;
         my $n = $path->n_start;
         my $total = 0;
         my $k = 2*$offset_3k;
         while (@got < $count) {
           ### @got
           my $n_end = 3**$k;
           for ( ; $n < $n_end; $n++) {
             $total += (dxdy_to_dir3($path->n_to_dxdy($n)) == $dir);
           }
           if ($offset_3k) {
             push @got, $total - 3**($k-1);
           } else {
             push @got, $total;
           }
           $k++;
         }
         return \@got;
       });
}

sub dxdy_to_dir3 {
  my ($dx,$dy) = @_;
  if ($dx == 2 && $dy == 0) {
    return 0;
  }
  if ($dx == -1) {
    if ($dy == 1) {
      return 1;
    }
    if ($dy == -1) {
      return 2;
    }
  }
  return undef;
}

#------------------------------------------------------------------------------
# A111286 boundary length is 2 then 3*2^k for points N <= 3^k
MyOEIS::compare_values
  (anum => 'A111286',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got = (1);
     for (my $k = 0; @got < $count; $k++) {
       push @got, MyOEIS::path_boundary_length ($path, 3**$k,
                                                lattice_type => 'triangular');
     }
     return \@got;
   });


# A007283 boundary length is 3*2^k for points N <= 3^k,
#         except initial
MyOEIS::compare_values
  (anum => 'A007283',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got = (3); # path initial boundary=2 vs bvalues=3
     for (my $k = 1; @got < $count; $k++) {
       push @got, MyOEIS::path_boundary_length ($path, 3**$k,
                                                lattice_type => 'triangular');
     }
     return \@got;
   });

# A164346 boundary even powers, is 3*4^n
# also one side, odd powers
MyOEIS::compare_values
  (anum => 'A164346',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got = (3);
     for (my $k = 1; @got < $count; $k++) {
       push @got, MyOEIS::path_boundary_length ($path, 3**(2*$k),
                                                lattice_type => 'triangular');
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => q{A164346},
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       push @got, MyOEIS::path_boundary_length ($path, 3**(2*$k+1),
                                                lattice_type => 'triangular',
                                                side => 'left');
     }
     return \@got;
   });

# A002023 boundary odd powers 6*4^n
# also even powers one side
MyOEIS::compare_values
  (anum => 'A002023',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       push @got, MyOEIS::path_boundary_length ($path, 3**(2*$k+1),
                                                lattice_type => 'triangular');
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => q{A002023},
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 1; @got < $count; $k++) {
       push @got, MyOEIS::path_boundary_length ($path, 3**(2*$k),
                                                lattice_type => 'triangular',
                                                side => 'right');
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A003945   R[k] boundary length

MyOEIS::compare_values
  (anum => 'A003945',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       push @got, MyOEIS::path_boundary_length ($path, 3**$k,
                                                side => 'right',
                                                lattice_type => 'triangular');
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A042950   V[k] boundary length

MyOEIS::compare_values
  (anum => 'A042950',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       push @got, MyOEIS::path_boundary_length ($path, 2 * 3**$k,
                                                side => 'left',
                                                lattice_type => 'triangular');
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A118004 1/2 enclosed area odd levels points N <= 3^(2k+1), is 9^k-4^k
# area[k] = 2*(3^(k-1)-2^(k-1))
# area[2k+1]/2 = 2*(3^(2k+1-1)-2^(2k+1-1))/2
#              = 9^k - 4^k

MyOEIS::compare_values
  (anum => 'A118004',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       my $area = MyOEIS::path_enclosed_area ($path, 3**(2*$k+1),
                                              lattice_type => 'triangular');
       push @got, $area/2;
     }
     return \@got;
   });

# A056182 enclosed area is 2*(3^(k-1)-2^(k-1)) for points N <= 3^k
MyOEIS::compare_values
  (anum => 'A056182',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 1; @got < $count; $k++) {
       push @got, MyOEIS::path_enclosed_area ($path, 3**$k,
                                              lattice_type => 'triangular');
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A136442 1,1,0,1,1,0,1,0,0,1,1,0,1,1,0,1,0,0,1,1,0,1,0,0,
# OFFSET =0,1,2,3,...
# left    1,1,0,1,1,0,0,1,0,1,1,0,1,1,0,0,1,0,0,1,0,1,1,0,0,1,0,1,1,0,1,1,0,0,1,0,1,1,0,1,1,0,0,1,0,0,1,0,1,1,0,0,1,0,0,1,0,1,1,0,0,1,0,1,1,0,1,1,0,0,1,0,0,1,0,1,1,0,0,1,0,1,1,0,1,1,0,0,1,0,1,1,0,1,1,0,0,1,0,0,1,0,1,1,0
#         N=1,2,3,...

# Not quite
#
# MyOEIS::compare_values
#   (anum => 'A136442',
#    func => sub {
#      my ($count) = @_;
#      my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
#                                                  turn_type => 'Left');
#      my @got = (1);
#      while (@got < $count) {
#        my ($i, $value) = $seq->next;
#        push @got, $value;
#      }
#      return \@got;
#    });

#------------------------------------------------------------------------------
# A060032 - turn 1=left, 2=right as bignums to 3^level

MyOEIS::compare_values
  (anum => 'A060032',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'LSR');
     my @got;
     for (my $level = 0; @got < $count; $level++) {
       my $big = Math::BigInt->new(0);
       foreach my $n (1 .. 3**$level) {
         my $value = $seq->ith($n);
         if ($value == -1) { $value = 2; }
         $big = 10*$big + $value;
       }
       push @got, $big;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A189673 - morphism turn 1=left, 0=right, extra initial 0

MyOEIS::compare_values
  (anum => 'A189673',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Left');
     my @got = (0);
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A189640 - morphism turn 0=left, 1=right, extra initial 0

MyOEIS::compare_values
  (anum => 'A189640',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my @got = (0);
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A062756 - ternary count 1s, is cumulative turn

MyOEIS::compare_values
  (anum => 'A062756',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'LSR');
     my @got;
     my $cumulative = 0;
     for (;;) {
       push @got, $cumulative;
       last if @got >= $count;
       my ($i, $value) = $seq->next;
       $cumulative += $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A080846 - turn 0=left, 1=right

MyOEIS::compare_values
  (anum => 'A080846',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A038502 - taken mod 3 is turn 1=left, 2=right

MyOEIS::compare_values
  (anum => 'A038502',
   fixup => sub {         # mangle to mod 3
     my ($bvalues) = @_;
     @$bvalues = map { $_ % 3 } @$bvalues;
   },
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value+1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A026225 - N positions of left turns

MyOEIS::compare_values
  (anum => 'A026225',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Left');
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 1) {
         push @got, $i;
       }
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A026225},
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       if (ternary_digit_above_low_zeros($n) == 1) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A026179 - positions of right turns

MyOEIS::compare_values
  (anum => 'A026179',
   func => sub {
     my ($count) = @_;
     my @got = (1);   # extra initial 1 ...
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 1) {
         push @got, $i;
       }
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => q{A026179},
   func => sub {
     my ($count) = @_;
     my @got = (1);
     for (my $n = 1; @got < $count; $n++) {
       if (ternary_digit_above_low_zeros($n) == 2) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
