#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2019, 2020, 2021 Kevin Ryde

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


# cf
# A141104 Lower Even Swappage of Upper Wythoff Sequence.
# A141105 Upper Even Swappage of Upper Wythoff Sequence.
# A141106 Lower Odd Swappage of Upper Wythoff Sequence.
# A141107 Upper Odd Swappage of Upper Wythoff Sequence.
#
# decimal digits of sum reciprocals of row 2 to 5
# A228040, A228041, A228042, A228043

use 5.004;
use strict;
use Carp 'croak';
use List::Util 'max';
use Math::BigInt try => 'GMP';
use Math::BaseCnv 'cnv';
use Math::NumSeq::Fibbinary;
use Math::NumSeq::FibbinaryBitCount;
use Math::NumSeq::FibonacciWord;
use Test;
plan tests => 47;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::WythoffArray;
use Math::PlanePath::CoprimeColumns;
*_coprime = \&Math::PlanePath::CoprimeColumns::_coprime;
use Math::PlanePath::Diagonals;
use Math::NumSeq::PlanePathTurn;

# uncomment this to run the ### lines
# use Smart::Comments '###';


# P+A=B P=B-A
sub pair_left_justify {
  my ($a,$b) = @_;
  my $count = 0;
  while ($a <= $b) {
    ($a,$b) = ($b-$a,$a);
    if ($count > 10) {
      die "oops cannot left justify $a,$b";
    }
  }
  return ($a,$b);
}

# path_find_row_with_pair() returns the row Y which contains the Fibonacci
# sequence which includes $a,$b somewhere, so W(X,Y)==$a and W(X+1,Y)==$b.
#
# If $a,$b are before the start of a row then the pair are stepped forward
# as necessary.  So they specify a Fibonacci-type recurrent sequence which
# is sought.
#
sub path_find_row_with_pair {
  my ($path, $a, $b) = @_;
  ### path_find_row_with_pair(): "$a, $b"
  if (($a == 0 && $b == 0) || $b < 0) {
    croak "path_find_row_with_pair $a,$b";
  }
  for (my $count = 0; $count < 50; ($a,$b) = ($b,$a+$b)) {
    ### at: "a=$a b=$b"
    my ($x,$y) = $path->n_to_xy($a) or next;
    if ($path->xy_to_n($x+1,$y) == $b) {
      ### found: " $a $b at X=$x, Y=$y"
      return $y;
    }
  }
  die "oops, pair $a,$b not found";
}

{
  my $seq = Math::NumSeq::Fibbinary->new;
  sub to_Zeck_bitstr {
    my ($n) = @_;
    return sprintf '%b', $seq->ith($n);
  }
  ok (to_Zeck_bitstr(12), 10101);
}

#------------------------------------------------------------------------------
# A114579 -- N at transpose Y,X
#
# In Zeckendorf base
# not in OEIS: 1,101,1001,10,10001,100,1010,10101,1000,10100

MyOEIS::compare_values
  (anum => 'A114579',
   # max_count => 100,  # big b-file
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy (Math::BigInt->new($n));
       my $t = $path->xy_to_n ($y, $x);
       push @got, $t;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A186007 -- row(i+j) - row(i)

# R(4,1) row 4+1=5 sub row 1
# row=5  |  12   20   32   52   84  136  220  356  576  932 1508
# row=1  |   1    2    3    5    8   13   21   34   55   89  144
#           11   18   29
# tail of row2

# R(4,3) row 4+3=7 sub row 4
# row=7  |  17   28   45   73  118  191  309  500  809 1309 2118
# row=4  |   9   15   24   39   63  102  165  267  432  699 1131
#            8   13
# tail of row=1 fibs

# row=7  |  17   28   45   73  118  191  309  500  809 1309 2118
# row=3  |   6   10   16   26   42   68  110  178  288  466  754
#           11   18
# tail of row=2 lucas

# B-values
# 1,                    pos=0
# 1,1,                  pos=1 to 2
# 1,1, 1,               pos=3 to 5
# 2,1, 3,1,             pos=6 to 9
# 1,3, 1,1,1,           pos=10 to 14
# 3,1, 1,1,1,1,         pos=15 to 20
# 2,4, 3,3,2,1,1,       pos=21 to 27
# 1,2, 8,1,3,1,1,1,
# 4,1, 1,3,1,2,1,3,1,
# 3,6, 4,2,4,1,3,1,1,1,
# 2,3,11,1,2,3,1,2,1,1,1,
# 5

# 1,                 pos=0
# 1,1,               pos=1 to 2
# 1,1, 1,             pos=3 to 5
# 2,1, 3,1,           pos=6 to 9
# 1,3, 1,1,1,         pos=10 to 14
# 3,1, 2,1,1,1,       pos=15 to 20     <-
# 2,4, 1,3,2,1,1,     pos=21 to 27     <-
# 1,2, 3,1,3,1,1,1,
# 4,1, 8,3,1,2,1,3,1,
# 3,6, 1,2,4,1,3,1,1,1,
# 2,3, 4,1,2,3,1,2,1,1,1,
# 5

# row 9 of W:      22,36,58,94,...
# row 3 of W:       6,10,16,26,...
#
# (row 9)-(row 3): 16,26,42,68  tail of row 3

# code          1....3....1....2....1....3....8....1....4....
# data          1....3....1....     1....3....8....1....4....11


{
  my $path = Math::PlanePath::WythoffArray->new (x_start=>1, y_start=>1);
  my $diag = Math::PlanePath::Diagonals->new    (x_start=>1, y_start=>1,
                                                 direction => 'up',
                                                 n_start => 1);
  sub my_A186007 {
    my ($n) = @_;
    if ($n < 1) { die; }
    my ($i,$j) = $diag->n_to_xy($n);  # by anti-diagonals
    ($i,$j) = ($i+$j, $j);

    my $ia = $path->xy_to_n(1,$i) or die;
    my $ib = $path->xy_to_n(2,$i) or die;
    my $ja = $path->xy_to_n(1,$j) or die;
    my $jb = $path->xy_to_n(2,$j) or die;

    my $da = $ia-$ja;
    my $db = $ib-$jb;
    my $d = path_find_row_with_pair($path, $da,$db);

    # print "n=$n i=$i iab=$ia,$ib j=$j jab=$ja,$jb diff=$da,$db at d=$d\n";
    return $d;
  }

  # foreach my $y (1 .. 5) {
  #   print "               ";
  #   foreach my $x (1 .. 10) {
  #     my $n = $diag->xy_to_n($x,$y);
  #     printf "%d....", my_A186007($n);
  #   }
  #   print "\n\n";
  # }
  #
  # print "R(2,6) = ",$diag->xy_to_n(6,2),"\n";
}

MyOEIS::compare_values
  (anum => 'A186007',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       push @got, my_A186007($n);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A185735 -- row(i)+row(j) of left-justified array
# 1 0 1 1 2 3
# 2 1 3 4 7 11
# 2 0 2 2 4 6
# 3 0 3 3 6 9
# 4 0 4 4 8 12
# 3 1 4 5 9 14
# row1+row2= 1,0+2,1 = 3,1 = row6
# row1+row3= 1,0+2,0 = 4,0 = row4

MyOEIS::compare_values
  (anum => 'A185735',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new (x_start=>1, y_start=>1);

     # Y>=1, 0<=X<Y
     my $diag = Math::PlanePath::Diagonals->new (x_start=>1, y_start=>1);
     my @got;
     for (my $d = $diag->n_start; @got < $count; $d++) {
       my ($i,$j) = $diag->n_to_xy($d);  # by anti-diagonals
       # if ($i > $j) { ($i,$j) = ($j,$i); }

       my $ia = $path->xy_to_n(1,$i) or die;
       my $ib = $path->xy_to_n(2,$i) or die;
       my $ja = $path->xy_to_n(1,$j) or die;
       my $jb = $path->xy_to_n(2,$j) or die;
       ($ia,$ib) = pair_left_justify($ia,$ib);
       ($ja,$jb) = pair_left_justify($ja,$jb);
       push @got, path_find_row_with_pair($path, $ia+$ja, $ib+$jb);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A165357 - Left-justified Wythoff Array by diagonals

{
  my $path = Math::PlanePath::WythoffArray->new;
  sub left_justified_row_start {
    my ($y) = @_;
    return pair_left_justify($path->xy_to_n(0,$y),
                             $path->xy_to_n(1,$y));
  }
  sub left_justified_xy_to_n {
    my ($x,$y) = @_;
    my ($a,$b) = left_justified_row_start($y);
    foreach (1 .. $x) {
      ($a,$b) = ($b,$a+$b);
    }
    return $a;
  }

  # foreach my $y (0 .. 5) {
  #   foreach my $x (0 .. 10) {
  #     printf "%3d ", left_justified_xy_to_n($x,$y);
  #   }
  #   print "\n";
  # }
}

MyOEIS::compare_values
  (anum => 'A165357',
   func => sub {
     my ($count) = @_;
     my $diag = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $d = $diag->n_start; @got < $count; $d++) {
       my ($x,$y) = $diag->n_to_xy($d);  # by anti-diagonals
       push @got, left_justified_xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A185737 -- accumulation array, by antidiagonals
# accumulation being total sum N in rectangle 0,0 to X,Y

MyOEIS::compare_values
  (anum => 'A185737',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new;
     my $diag = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $d = $diag->n_start; @got < $count; $d++) {
       my ($x,$y) = $diag->n_to_xy($d);  # by anti-diagonals
       push @got, path_rect_to_accumulation($path, 0,0, $x,$y);
     }
     return \@got;
   });

sub path_rect_to_accumulation {
  my ($path, $x1,$y1, $x2,$y2) = @_;
  # $x1 = round_nearest ($x1);
  # $y1 = round_nearest ($y1);
  # $x2 = round_nearest ($x2);
  # $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  my $accumulation = 0;
  foreach my $x ($x1 .. $x2) {
    foreach my $y ($y1 .. $y2) {
      $accumulation += $path->xy_to_n($x,$y);
    }
  }
  return $accumulation;
}

#------------------------------------------------------------------------------
# A173028 -- row number which is x * row(y), by diagonals

# Return pair ($a,$b) which is in the $k'th coprime row of WythoffArray $path
# First pair at $k==1.
sub coprime_pair {
  my ($path, $k) = @_;
  my $x = $path->x_minimum;
  for (my $y = $path->y_minimum; ; $y++) {
    my $a = $path->xy_to_n($x,  $y);
    my $b = $path->xy_to_n($x+1,$y);
    if (_coprime($a,$b)) {
      $k--;
      if ($k <= 0) {
        return ($a,$b);
      }
    }
  }
}

# Return the row number Y of WythoffArray $path which contains $multiple
# times the $k'th coprime row.
sub path_y_of_multiple {
  my ($path, $multiple, $k) = @_;
  ### path_y_of_multiple: "$multiple,$k"
  if ($multiple < 1) {
    croak "path_y_of_multiple multiple=$multiple";
  }
  ($a,$b) = coprime_pair($path,$k);
  return path_find_row_with_pair($path, $a*$multiple, $b*$multiple);
}
# {
#   my $path = Math::PlanePath::WythoffArray->new (x_start=>1, y_start=>1);
#   foreach my $y (1 .. 5) {
#     foreach my $x (1 .. 10) {
#       printf "%3d ", path_y_of_multiple($path,$x,$y)//-1;
#     }
#     print "\n";
#   }
# }

MyOEIS::compare_values
  (anum => 'A173028',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new (x_start=>1, y_start=>1);
     my $diag = Math::PlanePath::Diagonals->new (x_start => $path->x_minimum,
                                                 y_start => $path->y_minimum,
                                                 direction => 'up');
     my @got;
     for (my $d = $diag->n_start; @got < $count; $d++) {
       my ($x,$y) = $diag->n_to_xy($d);  # by anti-diagonals
       push @got, path_y_of_multiple($path,$x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A139764 -- lowest Zeckendorf term fibonacci value,
#   is N on X axis for the column containing n

MyOEIS::compare_values
  (anum => 'A139764',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $path->xy_to_n($x,0);   # down to axis

       # Across to Y axis, not in OEIS
       # push @got, $path->xy_to_n(0,$y);   # across to axis
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A220249 -- which row is n * Lucas numbers

MyOEIS::compare_values
  (anum => 'A220249',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new (x_start=>1, y_start=>1);
     my @got;
     for (my $k = 1; @got < $count; $k++) {
       # Lucas numbers starting 1, 3
       push @got, path_find_row_with_pair($path, $k, $k*3);
                                                  }
       return \@got;
   });

#------------------------------------------------------------------------------
# A173027 -- which row is n * Fibonacci numbers

MyOEIS::compare_values
  (anum => 'A173027',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new (x_start=>1, y_start=>1);
     my @got;
     for (my $k = 1; @got < $count; $k++) {
       # Fibonacci numbers starting 1, 1
       push @got, path_find_row_with_pair($path, $k, $k);
                                                  }
       return \@got;
   });

#------------------------------------------------------------------------------
# A035614 -- X coord, starting 0
#   but is OFFSET=0 so start N=0

MyOEIS::compare_values
  (anum => 'A035614',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $x;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A188436 -- [3r]-[nr]-[3r-nr], where r=(1+sqrt(5))/2 and []=floor.
# positions of right turns
# Y axis turn right: 0 1 00 101 00 1 00 101
# Fibonacci word:    0 1 00 101 00 1 00 101
#
# N on Y axis
# 101010
# 101001
# 100101
# 100001
#  10101
#  10001
#   1001
#    101
#      1

# A188436: 00000 001000000010000100000001000000010000100000001000010000000100000
# path:          001000000010000100000001000000010000100000001000010000000100000

MyOEIS::compare_values
  (anum => 'A188436',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'WythoffArray',
                                                 turn_type => 'Right');
     my @got = (0,0,0,0,0);
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

use constant PHI => (1 + sqrt(5)) / 2;
use POSIX 'floor';
sub A188436_func {
  my ($n) = @_;
  floor(3*PHI) - floor($n*PHI)-floor(3*PHI-$n*PHI);
}

{
  my $seq = Math::NumSeq::Fibbinary->new;
  my $bad = 0;
  foreach (1 .. 50000) {
    my ($i,$seq_value) = $seq->next;
    $seq_value = ($seq_value % 8 == 5 ? 1 : 0);
    # if ($seq_value) { print "$i," }
    my $func_value = A188436_func($i+4);
    if ($func_value != $seq_value) {
      print "$i  fibbinary seq=$seq_value func=$func_value\n";
      last if $bad++ > 20;
    }
  }
  ok (0, $bad);
}
{
  my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'WythoffArray',
                                              turn_type => 'Right');
  my $bad = 0;
  foreach (1 .. 50000) {
    my ($i,$seq_value) = $seq->next;
    my $func_value = A188436_func($i+4);
    if ($func_value != $seq_value) {
      print "$i  turn seq=$seq_value func=$func_value\n";
      last if $bad++ > 20;
    }
  }
  ok (0, $bad);
}
# [3r]-[(n+4)r]-[3r-(n+4)r]
# = [3r]-[(n+4)r]-[3r-nr-4r]
# = [3r]-[nr+4r]-[-r-nr]
# some of Y axis  4,12,17,25,33,38,46


#------------------------------------------------------------------------------
# A003622 -- Y coordinate of right turns is "odd" Zeckendorf base

MyOEIS::compare_values
  (anum => 'A003622',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value) {
         my ($x,$y) = $path->n_to_xy($i);
         $x == 0 or die "oops, right turn supposed to be at X=0";
         push @got, $y;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A134860 -- Wythoff AAB numbers
#   N position of right turns, being Zeckendorf ending "...101"

MyOEIS::compare_values
  (anum => 'A134860',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'WythoffArray',
                                                 turn_type => 'Right');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# Y axis 0=left,1=right is Fibonacci word

{
  my $path = Math::PlanePath::WythoffArray->new;
  my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                              turn_type => 'Right');
  my $fw = Math::NumSeq::FibonacciWord->new;
  my $bad = 0;
  foreach my $y (1 .. 1000) {
    my $n = $path->xy_to_n(0, Math::BigInt->new($y));
    my $seq_value = $seq->ith($n);
    my $fw_value = $fw->ith($y);
    if ($fw_value != $seq_value) {
      print "y=$y n=$n  seq=$seq_value fw=$fw_value\n";
      last if $bad++ > 20;
    }
  }
  ok (0, $bad);
}

#------------------------------------------------------------------------------
# A080164 -- Wythoff difference array
#   diff(x,y) = wythoff(2x+1,y) - wythoff(2x,y)

MyOEIS::compare_values
  (anum => 'A080164',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new;
     my $diag = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $d = $diag->n_start; @got < $count; $d++) {
       my ($x,$y) = $diag->n_to_xy($d);  # by anti-diagonals
       push @got, $path->xy_to_n(2*$x+1,$y) - $path->xy_to_n(2*$x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A143299 number of Zeckendorf 1-bits in row Y
# cf A007895 which is the fibbinary bit count Math::NumSeq::FibbinaryBitCount

MyOEIS::compare_values
  (anum => 'A143299',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::FibbinaryBitCount->new;
     my $path = Math::PlanePath::WythoffArray->new;
     my @got;
     for (my $y = 0; @got < $count; $y++) {
       my $n = $path->xy_to_n(0,$y);
       push @got, $seq->ith($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A137707 secondary Wythoff array ???

# A137707 Secondary Wythoff Array read by antidiagonals.
# A137708 Secondary Lower Wythoff Sequence.
# A137709 Secondary Upper Wythoff Sequence.

# MyOEIS::compare_values
#   (anum => 'A137707',
#    func => sub {
#      my ($count) = @_;
#      my $path = Math::PlanePath::WythoffArray->new;
#      my $diag = Math::PlanePath::Diagonals->new;
#      my @got;
#      for (my $d = $diag->n_start; @got < $count; $d++) {
#        my ($x,$y) = $diag->n_to_xy($d);  # by anti-diagonals
#        if ($y % 2) {
#          push @got, $path->xy_to_n($x,$y-1) + 1;
#        } else {
#          push @got, $path->xy_to_n($x,$y);
#        }
#      }
#      return \@got;
#    });


#------------------------------------------------------------------------------
# A083398 -- anti-diagonals needed to cover numbers 1 to n
# maybe n_range_to_rect() ...
# max(X+Y) for 1 to n

MyOEIS::compare_values
  (anum => 'A083398',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new;
     my @got;
     my @diag;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       $diag[$n] = $x+$y + 1;  # +1 to count first diagonal as 1
       push @got, max(@diag[1..$n]);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# N in columns

foreach my $elem ([ 'A003622', 0 ], # N on Y axis,    OFFSET=1
                  [ 'A035336', 1 ], # N in X=1 column OFFSET=1
                  [ 'A066097', 1 ], # N in X=1 column, duplicate OFFSET=0

                  # per list in A035513
                  [ 'A035337', 2 ], # OFFSET=0
                  [ 'A035338', 3 ], # OFFSET=0
                  [ 'A035339', 4 ], # OFFSET=0
                  [ 'A035340', 5 ], # OFFSET=0
                 ) {
  my ($anum, $x, %options) = @$elem;

  MyOEIS::compare_values
      (anum => $anum,
       func => sub {
         my ($count) = @_;
         my $path = Math::PlanePath::WythoffArray->new;
         my @got = @{$options{'extra_initial'}||[]};
         for (my $y = Math::BigInt->new(0); @got < $count; $y++) {
           push @got, $path->xy_to_n ($x, $y);
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A160997 Antidiagonal sums of the Wythoff array A035513

MyOEIS::compare_values
  (anum => 'A160997',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new;
     my @got;
     for (my $d = 0; @got < $count; $d++) {
       my $total = 0;
       foreach my $x (0 .. $d) {
         $total += $path->xy_to_n($x,$d-$x);
       }
       push @got, $total;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A005248 -- every second N on Y=1 row, every second Lucas number

MyOEIS::compare_values
  (anum => q{A005248},
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new;
     my @got = (2,3); # initial skipped
     for (my $x = Math::BigInt->new(1); @got < $count; $x+=2) {
       push @got, $path->xy_to_n ($x, 1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# N on rows
# per list in A035513

foreach my $elem ([ 'A000045',  0, extra_initial=>[0,1] ], # X axis Fibonaccis

                  [ 'A006355',  2, extra_initial=>[1,0,2,2,4] ],
                  [ 'A022086',  3, extra_initial=>[0,3,3,6]   ],
                  [ 'A022087',  4, extra_initial=>[0,4,4,8]   ],
                  [ 'A000285',  5, extra_initial=>[1,4,5,9]   ],
                  [ 'A022095',  6, extra_initial=>[1,5,6,11]  ],

                  # sum of Fibonacci and Lucas numbers
                  [ 'A013655',  7, extra_initial=>[3,2,5,7,12] ],

                  [ 'A022112',  8, extra_initial=>[2,6,8,14]   ],
                  [ 'A022113',  9, extra_initial=>[2,7,9,16]   ],
                  [ 'A022120', 10, extra_initial=>[3,7,10,17]  ],
                  [ 'A022121', 11, extra_initial=>[3,8,11,19]  ],
                  [ 'A022379', 12, extra_initial=>[3,9,12,21]  ],
                  [ 'A022130', 13, extra_initial=>[4,9,13,22]  ],
                  [ 'A022382', 14, extra_initial=>[4,10,14,24] ],
                  [ 'A022088', 15, extra_initial=>[0,5,5,10,15,25] ],
                  [ 'A022136', 16, extra_initial=>[5,11,16,27] ],
                  [ 'A022137', 17, extra_initial=>[5,12,17,29] ],
                  [ 'A022089', 18, extra_initial=>[0,6,6,12,18,30] ],
                  [ 'A022388', 19, extra_initial=>[6,13,19,32] ],
                  [ 'A022096', 20, extra_initial=>[1,6,7,13,20,33] ],
                  [ 'A022090', 21, extra_initial=>[0,7,7,14,21,35] ],
                  [ 'A022389', 22, extra_initial=>[7,15,22,37] ],
                  [ 'A022097', 23, extra_initial=>[1,7,8,15,23,38] ],
                  [ 'A022091', 24, extra_initial=>[0,8,8,16,24,40] ],
                  [ 'A022390', 25, extra_initial=>[8,17,25,42] ],
                  [ 'A022098', 26, extra_initial=>[1,8,9,17,26,43], ],
                  [ 'A022092', 27, extra_initial=>[0,9,9,18,27,45], ],
                 ) {
  my ($anum, $y, %options) = @$elem;

  MyOEIS::compare_values
      (anum => $anum,
       func => sub {
         my ($count) = @_;
         my $path = Math::PlanePath::WythoffArray->new;
         my @got = @{$options{'extra_initial'}||[]};
         for (my $x = Math::BigInt->new(0); @got < $count; $x++) {
           push @got, $path->xy_to_n ($x, $y);
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A064274 -- inverse perm of by diagonals up from X axis

MyOEIS::compare_values
  (anum => 'A064274',
   func => sub {
     my ($count) = @_;
     my $diagonals  = Math::PlanePath::Diagonals->new (direction => 'up');
     my $wythoff = Math::PlanePath::WythoffArray->new;
     my @got = (0);  # extra 0
     for (my $n = $diagonals->n_start; @got < $count; $n++) {
       my ($x, $y) = $wythoff->n_to_xy ($n);
       $x = Math::BigInt->new($x);
       $y = Math::BigInt->new($y);
       push @got, $diagonals->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003849 -- Fibonacci word

MyOEIS::compare_values
  (anum => 'A003849',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new;
     my @got = (0);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, ($x == 0 ? 1 : 0);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A000201 -- N+1 for N not on Y axis, spectrum of phi

MyOEIS::compare_values
  (anum => 'A000201',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new;
     my @got = (1);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       if ($x != 0) {
         push @got, $n+1;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A022342 -- N not on Y axis, even Zeckendorfs

MyOEIS::compare_values
  (anum => 'A022342',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new;
     my @got = (0);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       if ($x != 0) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A001950 -- N+1 of the N's on Y axis, spectrum

MyOEIS::compare_values
  (anum => 'A001950',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WythoffArray->new;
     my @got;
     for (my $y = 0; @got < $count; $y++) {
       my $n = $path->xy_to_n(0,$y);
       push @got, $n+1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A083412 -- by diagonals, down from Y axis

MyOEIS::compare_values
  (anum => 'A083412',
   func => sub {
     my ($count) = @_;
     my $diagonals  = Math::PlanePath::Diagonals->new (direction => 'down');
     my $wythoff = Math::PlanePath::WythoffArray->new;
     my @got;
     for (my $n = $diagonals->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonals->n_to_xy ($n);
       push @got, $wythoff->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A035513 -- by diagonals, up from X axis

MyOEIS::compare_values
  (anum => 'A035513',
   func => sub {
     my ($count) = @_;
     my $diagonals  = Math::PlanePath::Diagonals->new (direction => 'up');
     my $wythoff = Math::PlanePath::WythoffArray->new;
     my @got;
     for (my $n = $diagonals->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonals->n_to_xy ($n);
       $x = Math::BigInt->new($x);
       $y = Math::BigInt->new($y);
       push @got, $wythoff->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
