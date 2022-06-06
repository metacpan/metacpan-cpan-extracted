#!/usr/bin/perl -w

# Copyright 2013, 2021 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use List::Util 'max';
use Math::Factor::XS 0.39 'prime_factors'; # version 0.39 for prime_factors()
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # grep for trajectories
  require Math::OEIS::Grep;

  foreach my $n (1..200) {
    my $t = $n;
    my @array = ($t, map { $t=step($t) } 1..50);
    ### @array
    Math::OEIS::Grep->search(array => \@array,
                             name => "starting n=$n",
                             verbose => 0,
                            );
  }
  exit 0;

  sub step {
    my ($n) = @_;
    return ($n & 1 ? 3*$n+1 : $n>>1);
  }
}

# to_peak
# 1
# 2, 1                  0
# 3, 10, 5, *16         3
# 4, 2, 1               0
# 5, *16, 8, 4, 2, 1    1
# 6, 3, 10, 5, 16       4

{
  # n=138367  peak=2798323360    is 2*32
  # n=5656191 peak=2412493616608 is 2**53

  foreach my $n (1,2,3,7,15,27,255,447,639,703,1819,4255,4591,9663,20895,26623,31911,60975,77671,113383,138367,159487,270271,665215,704511,1042431,1212415,1441407,1875711,1988859,2643183,2684647,3041127,3873535,4637979,5656191) {
    my $peak = collatz_peak($n);
    last if $peak >= 2**64;
    print "$n  $peak\n";
  }
  # my $seq = Math::NumSeq::OEIS->new(anum=>'A006885');
  # while (my ($i,$value) = $seq->next) {
  #   if ($value >= 2**32) {
  #     last;
  #   }
  #   $n = $i;
  # }
  exit 0;
}

{
  # A025586 peak reached
  # A006884 n which gives new higher peak
  # A006885 steps of new higher peak
  # A025587 record setters

  my $record = 0;
  foreach my $n (1 .. 2000) {
    my $peak = collatz_peak($n);
    if ($peak > $record) {
      $record = $peak;
      print "$n,";
    }
  }
  exit 0;

  sub collatz_peak {
    my ($n) = @_;
    my $peak = $n;
    while ($n > 1) {
      if ($n % 2) {
        $n = 3*$n + 1;
      } else {
        $n /= 2;
      }
      $peak = max($n,$peak);
    }
    return $peak;
  }
}

{
  # reverse steps

  # 3k+1 = 4n
  # 3k = 4n+1
  # k = (4n+1)/3

  N: foreach my $n (1 .. 20) {
    print "n=$n\n";
    for (1 .. 10) {
      my $count = 0;
      until ($n%3 == 2) {
        $n *= 2;
        print "$n  doubled\n";
        if (++$count > 6) {
          next N;
        }
      }

      $n = ($n+1) / 3;
      print "$n\n";
      $n == int($n) or die;
    }
    print "\n";
  }
  exit 0;
}
