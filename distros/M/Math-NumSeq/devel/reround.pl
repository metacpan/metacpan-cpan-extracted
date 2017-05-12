#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use POSIX;
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099
use List::Util 'max','min';
use Math::Trig 'pi';

#use Smart::Comments;


{
  require Math::NumSeq::ReRound;
  my @seqs = map { Math::NumSeq::ReRound->new (extra_multiples => $_) } 0 .. 5;
  foreach (1 .. 50) {
    my ($i,$value) = $seqs[0]->next;
    print "$i $value   ";
    foreach my $j (1 .. $#seqs) {
      my (undef,$v2) = $seqs[$j]->next;
      my $diff = $v2-$value;
      printf " %+d", $diff;
      $value = $v2;
    }
    print "\n";
  }
  exit 0;
}

{
  # value_to_i_estimate() by extra_multiples

  require Math::NumSeq::ReRound;
  for my $extra_multiples (12,
                           0,1,2,3,4,5,6,7,8,9,10,
                           11,12,
                           20,30,40,
                           100,
                           1000,
                           10000,
                           100000,
                           1000000,
                           10000000,
                           100000000,
                           1000000000,
                          ) {
    my $seq = Math::NumSeq::ReRound->new (extra_multiples => $extra_multiples);
    my $i = 100000;
    my $value = $seq->ith($i);
    my $est_i = $seq->value_to_i_estimate($value);
    my $factor = (ref $est_i ? $est_i->numify : $est_i) / $i;
    printf "%d %d   %.10s  factor=%.8f\n",
      $extra_multiples, $value, $est_i, $factor;
  }
  exit 0;
}

{
  # value_to_i_estimate()
  require Math::NumSeq::ReRound;
  my $seq = Math::NumSeq::ReRound->new (extra_multiples => 9);

  # sqrt(pi*value)
  #  0 1.000          
  #  1 1.571          
  #  2 2.000     2    
  #  3 2.355          
  #  4 2.66665   8/3  
  #  5 2.944          
  #  6 3.198          
  #  7 3.436          
  #  8 3.656          
  #  9 3.864          
  # 10 4.062          
  # 11 4.250    17/4  
  # 12 4.430          
  # 13 4.606
  # 14 4.77352
  # 15 4.93526
  # 16 5.09189
  # 17 5.24373
  # 18 5.39084
  # 20 5.67340
  # 100 12.56171  squared 157.79
  # 1000 39.63703 squared 1571.094
  # 100000 396.26259 squared 157024.04
  #
  # est(k) = f(k) * sqrt(pi*value)
  # f(k) = sqrt(k*pi/2)
  # est(k) = sqrt(k*pi/2) * sqrt(pi*value)
  #        = sqrt(k*pi/2 * pi*value)

  my $target = 2;
  for (;;) {
    my ($i, $value) = $seq->next;
    if ($i >= $target) {
      $target *= 1.1;

      # require Math::BigInt;
      # $value = Math::BigInt->new($value);

      # require Math::BigRat;
      # $value = Math::BigRat->new($value);

      # require Math::BigFloat;
      # $value = Math::BigFloat->new($value);

      my $est_i = $seq->value_to_i_estimate($value);
      my $factor = (ref $est_i ? $est_i->numify : $est_i) / $i;
      printf "%d %d   %.10s  factor=%.5f\n",
        $i, $est_i, $value, $factor;
    }
  }
  exit 0;
}




{
  # sqrt(pi*value)
  my @a = (qw(
               1.000
               1.571
               2.000
               2.355
               2.66665
               2.944
               3.198
               3.436
               3.656
               3.864
               4.062
               4.250
               4.430
               4.606
               4.77352
               4.93526
               5.09189
               5.24373
               5.67340
            ));
  foreach my $a (@a) {
    my $sq = $a*$a;
    print "$sq\n";
  }
  exit 0;
}
