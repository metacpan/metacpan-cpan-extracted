#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2018 Kevin Ryde

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
plan tests => 11;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::GosperSide;
my $path = Math::PlanePath::GosperSide->new;

{
  my %dxdy_to_dir6 = ('2,0' => 0,
                      '1,1' => 1,
                      '-1,1' => 2,
                      '-2,0' => 3,
                      '-1,-1' => 4,
                      '1,-1' => 5);

  # return 0 if X,Y's are straight, 2 if left, 1 if right
  sub xy_turn_6 {
    my ($prev_x,$prev_y, $x,$y, $next_x,$next_y) = @_;
    my $prev_dx = $x - $prev_x;
    my $prev_dy = $y - $prev_y;
    my $dx = $next_x - $x;
    my $dy = $next_y - $y;

    my $prev_dir = $dxdy_to_dir6{"$prev_dx,$prev_dy"};
    if (! defined $prev_dir) { die "oops, unrecognised $prev_dx,$prev_dy"; }

    my $dir = $dxdy_to_dir6{"$dx,$dy"};
    if (! defined $dir) { die "oops, unrecognised $dx,$dy"; }

    return ($dir - $prev_dir) % 6;
  }
}


#------------------------------------------------------------------------------
# A229215 - direction 1,2,3,-1,-2,-3 

{
  my %dxdy_to_dirpn3 = ('2,0' => 1,      #      -2   -3
                        '1,-1' => 2,     #        \ /
                        '-1,-1' => 3,    #   -1 ---*--- 1
                        '-2,0' => -1,    #        / \ 
                        '-1,1' => -2,    #       3   2
                        '1,1' => -3);
  MyOEIS::compare_values
      (anum => 'A229215',
       func => sub {
         my ($count) = @_;
         my @got;
         for (my $n = $path->n_start; @got < $count; $n++) {
           my ($dx,$dy) = $path->n_to_dxdy($n);
           my $dir = $dxdy_to_dirpn3{"$dx,$dy"};
           die if ! defined $dir;
           push @got, $dir;
         }
         return \@got;
       });
}


#------------------------------------------------------------------------------
# A005823 - N ternary no 1s is net turn 0

MyOEIS::compare_values
  (anum => 'A005823',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'LSR');
     my $total_turn = 0;
     my @got = (0);
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $total_turn += $value;
       if ($total_turn == 0) {
         push @got, $i;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A099450 - Y at N=3^k

MyOEIS::compare_values
  (anum => 'A099450',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::BigInt;
     for (my $k = Math::BigInt->new(1); @got < $count; $k++) {
       my ($x,$y) = $path->n_to_xy(3**$k);
       push @got, $y;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A189673 - morphism turn 0=left, 1=right, extra initial 0

MyOEIS::compare_values
  (anum => 'A189673',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
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
     require Math::NumSeq::PlanePathTurn;
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
# A060032 - turn 1=left, 2=right as bignums to 3^level

MyOEIS::compare_values
  (anum => 'A060032',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     require Math::BigInt;
     for (my $level = 0; @got < $count; $level++) {
       my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                   turn_type => 'Right');
       my $big = Math::BigInt->new(0);
       foreach my $n (1 .. 3**$level) {
         my ($i, $value) = $seq->next;
         $big = 10*$big + $value+1;
       }
       push @got, $big;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A062756 - ternary count 1s, is cumulative turn left=+1, right=-1

MyOEIS::compare_values
  (anum => 'A062756',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'LSR');
     my @got = (0);  # bvalues starts with an n=0
     my $cumulative;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $cumulative += $value;
       push @got, $cumulative;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A080846 - turn 0=left, 1=right

MyOEIS::compare_values
  (anum => 'A080846',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
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
# A038502 - taken mod 3 is 1=left, 2=right

MyOEIS::compare_values
  (anum => 'A038502',
   fixup => sub {
     my ($bvalues) = @_;
     @$bvalues = map { $_ % 3 } @$bvalues;
   },
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
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
# A026225 - positions of left turns

MyOEIS::compare_values
  (anum => 'A026225',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Left');
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value) {
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
       if (digit_above_low_zeros($n) == 1) {
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
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my @got = (1);     # extra 1 ...
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value) {
         push @got, $i;
       }
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A026179',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     for (my $n = 1; @got < $count; $n++) {
       if (digit_above_low_zeros($n) == 2) {
         push @got, $n;
       }
     }
     return \@got;
   });

sub digit_above_low_zeros {
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
exit 0;
