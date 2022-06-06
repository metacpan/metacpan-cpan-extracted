#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2019, 2020, 2021, 2022 Kevin Ryde

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


# cf Lucas representation
#
# A130310 lucas rep minimal (greedy), not both 2,3 in sum
# A130311 lucas rep maximal
# A131343 lucas num bits (maximal)
# A116543 lucas num bits (greedy)
# A214974 lucas bits == zeck bits for A116543 greedy form
# A214975 lucas bits < zeck bits
# A214976 lucas bits > zeck bits


use 5.004;
use strict;
use Math::BaseCnv 'cnv';
use Test;
plan tests => 53;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099
use Math::NumSeq::DigitCount;
use Math::NumSeq::Fibbinary;
use Math::NumSeq::Fibonacci;

# uncomment this to run the ### lines
# use Smart::Comments '###';


#------------------------------------------------------------------------------
# Generic

# GP-DEFINE  default(strictargs,1);
# GP-DEFINE  default(parisizemax,50*10^6);
# GP-DEFINE  read("memoize.gp");
# GP-DEFINE  read("OEIS-data.gp");
# GP-DEFINE  read("OEIS-data-wip.gp");
# GP-DEFINE  read("Fibbinary-various.gp");
# GP-DEFINE  nearly_equal_epsilon = 1e-15;
# GP-DEFINE  nearly_equal(x,y, epsilon=nearly_equal_epsilon) = \
# GP-DEFINE    abs(x-y) < epsilon;

# GP-DEFINE  \\ Return a vector of the first n coefficients of
# GP-DEFINE  \\ generating function g, starting from term x^0.
# GP-DEFINE  \\ g is normally a polynomial fraction (type t_RFRAC)
# GP-DEFINE  \\ but a plain polynomial is accepted too and returns
# GP-DEFINE  \\ its lowest n coefficients.
# GP-DEFINE  gf_terms(g,n) = {
# GP-DEFINE    if(g==0,return(vector(n)));
# GP-DEFINE    my(x = variable(g),
# GP-DEFINE       zeros = min(n,valuation(g,x)),
# GP-DEFINE       v = Vec(g + O(x^n)));
# GP-DEFINE    if(zeros>=0, concat(vector(zeros,i,0), v),
# GP-DEFINE                 v[-zeros+1 .. #v]);
# GP-DEFINE  }
# GP-Test  gf_terms(1/(1-2*x), 3) == [1,2,4]

# GP-DEFINE  \\ g is a bivariate generating function Sum C*x^n*y^k
# GP-DEFINE  \\ return coeff C of term x^n*y^k
# GP-DEFINE  gf2_term(g,n,k) = {
# GP-DEFINE    g += O(x^(n+1));
# GP-DEFINE    g = polcoeff(g,n,'x);
# GP-DEFINE    g += O(y^(k+1));
# GP-DEFINE    polcoeff(g,k,'y);
# GP-DEFINE  }

# GP-DEFINE  select_first_n(f,n) = {
# GP-DEFINE    my(l=List([]), i=0);
# GP-DEFINE    while(#l<n, if(f(i),listput(l,i)); i++);
# GP-DEFINE    Vec(l);
# GP-DEFINE  }

# GP-DEFINE  red = phi-1;             \\ 0.618..
# GP-Test  red == 1/phi
# GP-DEFINE  F = fibonacci;

#------------------------------------------------------------------------------
# A003714 -- Fibbinary

# addition table of Fibbinary to Fibbinary
# OEIS_antidiagonals_of_func(30,(x,y)->A003714_Fibbinary(x+y), 1,1)
# OEIS_antidiagonals_of_func(30,(x,y)->A003714_Fibbinary(A022290_UnFibbinary(x)+A022290_UnFibbinary(y)), 0,0)
# vector(10,n, A003714_Fibbinary(n))


#------------------------------------------------------------------------------
# A189920 -- Zeckendorf base digits triangle rows

MyOEIS::compare_values
  (anum => 'A189920',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     $seq->seek_to_i(1);
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, split(//, sprintf('%b', $value));
     }
     $#got = $count-1;
     return \@got;
   });


#------------------------------------------------------------------------------
# A014417 -- n in fibonacci base, the Fibbinaries written out in binary

MyOEIS::compare_values
  (anum => 'A014417',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, sprintf '%b', $value;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A212529 -- Fibbinary num 00 pairs

foreach my $elem (
                  ['A212278', 3, 0 ],
                  # ['A007895', 7, 5 ],
                 ) {
  my ($anum, $mask, $bits, %option) = @$elem;
  MyOEIS::compare_values
      (anum => $anum,
       func => sub {
         my ($count) = @_;
         my $seq = Math::NumSeq::Fibbinary->new;
         my @got;
         for (my $n = 0; @got < $count; $n++) {
           push @got, count_overlapping_blocks($seq->ith($n), $mask, $bits);
         }
         return \@got;
       });

  # count 000
  # not in OEIS: 1,0,0,2,1,0,0,0,3,2,1,0,0,1,0,0,4,3
  # count 101
  # not in OEIS: 1,0,0,1,0,0,0,1,2,0,0,0,0,1,1,1,2,0,0,0,0,1,0,0,1
}
sub count_overlapping_blocks {
  my ($n, $mask, $bits) = @_;
  my $ret = 0;
  while ($n) { $ret += ($n&$mask)==$bits; $n>>=1; }
  return $ret;
}


#------------------------------------------------------------------------------
# A048678 - binary expand 1->01, so no adjacent 1 bits
# is a permutation of the fibbinary numbers

MyOEIS::compare_values
  (anum => 'A048678',
   func => sub {
     my ($count) = @_;
     return [map {expand_1_to_01($_)} 0..$count-1];
   });
sub expand_1_to_01 {
  my ($n) = @_;
  my $bits = digit_split($n,2);  # $bits->[0] low bit
  @$bits = map {$_==0 ? (0) : (1,0)} @$bits;
  return digit_join($bits,2);
}

# 1->10
MyOEIS::compare_values
  (anum => 'A124108',
   func => sub {
     my ($count) = @_;
     return [map {expand_1_to_10($_)} 0..$count-1];
   });
sub expand_1_to_10 {
  my ($n) = @_;
  my $bits = digit_split($n,2);  # $bits->[0] low bit
  @$bits = map {$_==0 ? (0) : (0,1)} @$bits;
  return digit_join($bits,2);
}

sub digit_split {
  my ($n, $radix) = @_;
  ### _digit_split(): $n

  if ($n == 0) {
    return [ 0 ];
  }
  my @ret;
  while ($n) {
    push @ret, $n % $radix;  # ret[0] low digit
    $n = int($n/$radix);
  }
  return \@ret;
}

sub digit_join {
  my ($aref, $radix) = @_;
  ### digit_join(): $aref

  my $n = 0;
  foreach my $digit (reverse @$aref) {  # high to low
    $n *= $radix;
    $n += $digit;
  }
  return $n;
}


#------------------------------------------------------------------------------
# A048679 - compressed Fibbinary mapping 01->1
# (permutation of the integers)

MyOEIS::compare_values
  (anum => 'A048679',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, compress_01_to_1($value);
     }
     return \@got;
   });

# also delete one 0 from each run of 0s
sub compress_01_to_1 {
  my ($value) = @_;
  my $ret = $value * 0; # inherit bignum
  my $retbit = 1;
  while ($value) {
    my $bits = $value & 3;
    if ($bits == 0 || $bits == 2) {
      $value >>= 1;
    } elsif ($bits == 1) {
      $ret += $retbit;
      $value >>= 2;
    } else {
      die "Oops compress_01 bits 11";
    }
    $retbit <<= 1;
  }
  return $ret;
}


#------------------------------------------------------------------------------
# A005206  Hofstadter G,
#   shift down each Zeckendorf index by 1
#   including F(2)=1 -> F(1)=1 unchanged

MyOEIS::compare_values
  (anum => 'A005206',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $value = $seq->ith($n);
       push @got, $seq->value_to_i_ceil(($value>>1) | ($value&1));
     }
     return \@got;
   });

# A060143 same except extra initial 0
MyOEIS::compare_values
  (anum => 'A060143',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got = (0);
     for (my $n = 0; @got < $count; $n++) {
       my $value = $seq->ith($n);
       push @got, $seq->value_to_i_ceil(($value>>1) | ($value&1));
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A003849 -- Fibonacci word, lowest Zeck bit
# Math::NumSeq::FibonacciWord

MyOEIS::compare_values
  (anum => 'A003849',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     for (my $n = 1; @got < $count; $n++) {  # but it actually OFFSET=0
       my $value = $seq->ith($n-1);
       push @got, $value & 1;
     }
     return \@got;
   });

# as values 1,2
MyOEIS::compare_values
  (anum => 'A003842',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       my $value = $seq->ith($n-1);
       push @got, ($value & 1) + 1;
     }
     return \@got;
   });

#--------
# A123740 -- characteristic of Wythoff AB,
#   second lowest bit of Zeck(n-1)
MyOEIS::compare_values
  (anum => 'A123740',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       my $value = $seq->ith($n-1);
       push @got, ($value >> 1) & 1;
     }
     return \@got;
   });

# A123740 -- char func Wythoff AB numbers A003623
#   second lowest bit of Zeck per comment by Franklin T. Adams-Watters
MyOEIS::compare_values
  (anum => 'A123740',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got = (0);
     for (my $n = 0; @got < $count; $n++) {
       my $value = $seq->ith($n+1);
       push @got, ($value >> 1) & 1;
     }
     return \@got;
   });
# A188009 -- [nr]-[nr-kr]-[kr]
#   second lowest bit of Zeck per Wolfdieter Lang formula A123740
MyOEIS::compare_values
  (anum => 'A188009',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got = (0,0,0);
     for (my $n = 0; @got < $count; $n++) {
       my $value = $seq->ith($n+1);
       push @got, ($value >> 1) & 1;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A003622 - odd Zeckendorfs, ending with 1

MyOEIS::compare_values
  (anum => 'A003622',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value & 1) { push @got, $i; }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A022342 - Zeckendorf even, i where value is even
#           floor(n*phi)-1
#           "Fibonacci successor"
# shift up Zeckendorf base, new low 0

MyOEIS::compare_values
  (anum => 'A022342',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if (($value % 2) == 0) {
         push @got, $i;
       }
     }
     return \@got;
   });
MyOEIS::compare_values       # = Zeckendorf shift up 1 place
  (anum => q{A022342},
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $seq->value_to_i($value<<1);
     }
     return \@got;
   });


#-------------
# Zeckendorf shift down 1 place (discard lowest digit)

MyOEIS::compare_values
  (anum => 'A319433',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Fibbinary->new;
     $seq->seek_to_value(2);  # A319433 OFFSET=2 omits initial 0 terms
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $seq->value_to_i($value>>1);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A062879 - Zeckendorf base 0 at even positions
#
# not the same as A054204 binary spread and recoded as Zeckendorf base

MyOEIS::compare_values
  (anum => 'A062879',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if (is_even_bits_zero($value)) {
         push @got, $i;
       }
     }
     return \@got;
   });
sub is_even_bits_zero {
  my ($n) = @_;
  for ( ; $n; $n>>=2) {
    if ($n&1) { return 0; }
  }
  return 1;
}


# Zeckendorf base 0 above each digit
# not in OEIS: 1,3,8,9,21,22,24,55,56,58,63,64,144,145,147
#
# MyOEIS::compare_values
#   (anum => 'A000001',
#    func => sub {
#      my ($count) = @_;
#      my $seq = Math::NumSeq::Fibbinary->new;
#      my @got;
#      while (@got < $count) {
#        my ($i, $value) = $seq->next;
#        my $value2 = sprintf '%b', $value;
#        my $spread2 = $value2; $spread2 =~ s/./0$&/g;
#        my $spread = oct("0b$spread2");
#        my $spread_i = $seq->value_to_i($spread);
#        printf "%d  %s %s -> %s %s  i=%d\n",
#          $i, $value,$value2, $spread2,$spread, $spread_i;
#        push @got, $spread_i;
#      }
#      return \@got;
#    });


#------------------------------------------------------------------------------
# A295897 runs of 1s all even length except odd lowest can be any
# Gray of Fibbinary

MyOEIS::compare_values
  (anum => 'A295897',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value ^ ($value >> 1);
     }
     return \@got;
   });

# Fibbinary no consecutive 1s so can add instead of xor
# so floor(3/2*Fibbinary)
MyOEIS::compare_values
  (anum => q{A295897},
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       # push @got, $value + ($value >> 1);
       push @got, ($value*3)>>1;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A022290 - bits as Fibonacci numbers
# without Math::NumSeq::Fibbinary restricting to no consecutive 1s

MyOEIS::compare_values
  (anum => 'A022290',
   func => sub {
     my ($count) = @_;
     my $fib = Math::NumSeq::Fibonacci->new;
     my @got;
     for (my $value = 0; @got < $count; $value++) {
       my $total = 0;
       for (my $i = 0; 1<<$i <= $value; $i++) {
         if ($value & (1<<$i)) {
           $total += $fib->ith($i+2);
         }
       }
       push @got, $total;
     }
     return \@got;
   });

#--------
# A062877 = bits as Fibonacci numbers F(2k+1)
#                4   2   0  evens
# Fibonacci  8 5 3 2 1 1 0
#              5   3   1    odds
#           Fibbinary |
# bits wxyz -> w0x0yz to get z as low 1, not Fibbinary
#
MyOEIS::compare_values
  (anum => 'A062877',
   func => sub {
     my ($count) = @_;
     my $fib = Math::NumSeq::Fibonacci->new;
     my @got;
     for (my $value = 0; @got < $count; $value++) {
       my $total = 0;
       for (my $i = 0; 1<<$i <= $value; $i++) {
         if ($value & (1<<$i)) {
           $total += $fib->ith(2*$i+1);
         }
       }
       push @got, $total;
     }
     return \@got;
   });


#--------
# A054204 = bits as Fibonacci numbers F(2k+2)
MyOEIS::compare_values
  (anum => 'A054204',  # OFFSET=1
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     for (my $b = 1; @got < $count; $b++) {
       my $b2 = cnv($b,10,2);
       my $spread = cnv($b2,4,10);
       push @got, $seq->value_to_i($spread);
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => 'A054204',
   func => sub {
     my ($count) = @_;
     my $fib = Math::NumSeq::Fibonacci->new;
     my @got;
     for (my $value = 1; @got < $count; $value++) {
       my $total = 0;
       for (my $i = 0; 1<<$i <= $value; $i++) {
         if ($value & (1<<$i)) {
           $total += $fib->ith(2*$i+2);
         }
       }
       push @got, $total;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A000045 - Fibonacci number is how many Fibbinary's of given bit length

MyOEIS::compare_values
  (anum => 'A000045',
   max_count => 12,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got = (0,1);
     my $target = 1;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value >= $target) {
         push @got, $i - $seq->i_start;
         $target *= 2;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054204 - has only even Fibs

MyOEIS::compare_values
  (anum => 'A054204',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     $seq->next;  # not initial 0
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if (all_odds_0($value)) {
         push @got, $i;
       }
     }
     return \@got;
   });

# Return true if all odd bit positions in $n are 0, where least significant
# bit is position number 0.
sub all_odds_0 {
  my ($n) = @_;
  while ($n) {
    if ($n & 2) { return 0; }
    $n >>= 2;
  }
  return 1;
}

#------------------------------------------------------------------------------
# A095734 least 0<->1 flips to make Zeck into palindrome

MyOEIS::compare_values
  (anum => 'A095734',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, asymmetry_index($value);
     }
     return \@got;
   });

# A037888 least 0<->1 to make binary palindrome
MyOEIS::compare_values
  (anum => 'A037888',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       push @got, asymmetry_index($n);
     }
     return \@got;
   });

# Return count number of bits in $n which must be changed to make it a
# palindrome.  Being how many bits differ in top half and bottom half.
use Math::NumSeq::Repdigits;
sub asymmetry_index {
  my ($n) = @_;
  my @bits = Math::NumSeq::Repdigits::_digit_split_lowtohigh($n,2)
    or return 0;
  my $numbits = scalar(@bits);
  my $count = 0;
  # numbits=5 run i=0,1
  # numbits=6 run i=0,1,2
  # numbits=7 run i=0,1,2
  foreach my $i (0 .. ($numbits >> 1)-1) {
    $count += ($bits[$i] ^ $bits[-1-$i]);
  }
  return $count;
}


#------------------------------------------------------------------------------
# A095309 -- palindrome in both binary and Zeckendorf base
# cf A006995 binary palindromes
#    A094202 Zeckendorf palindromes

MyOEIS::compare_values
  (anum => 'A095309',
   max_value => 100000,     # bit slow
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Palindromes;
     my $palindrome = Math::NumSeq::Palindromes->new (radix => 2);
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got = (0,1,3);
     $palindrome->next; # skip 0
     $palindrome->next; # skip 3
     while (@got < $count) {
       my ($i, $value) = $palindrome->next;
       my $zeck = $seq->ith($value);
       ### $value
       ### zeck: sprintf '%b', $zeck
       if ($palindrome->pred($zeck)) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A094202 -- palindrome in Zeckendorf base

MyOEIS::compare_values
  (anum => 'A094202',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Palindromes;
     my $palindrome = Math::NumSeq::Palindromes->new (radix => 2);
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($palindrome->pred($value)) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A095730 -- primes which are palindromes in Zeckendorf base

MyOEIS::compare_values
  (anum => 'A095730',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Palindromes;
     my $palindrome = Math::NumSeq::Palindromes->new (radix => 2);
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if (is_prime($i) && $palindrome->pred($value)) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A210619 -- n equal number of 1-bits and 0-bits in Zeckendorf base
#
# n numbers of 2n bits
# Runs of 100101...01        pairs 10 or 01
#         101010...01
#         101010...10
# means position "00" at successively lower positions.

MyOEIS::compare_values
  (anum => 'A210619',
   func => sub {
     my ($count) = @_;

     require Math::BigInt;
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     for (my $c = 1; @got < $count; $c++) {
       my $str = ('10' x ($c-1)) . '1';
       ### $str
       my @i;
       for (my $pos = 1; $pos <= length($str); $pos += 2) {
         my $v = $str;
         substr($v,$pos,0) = '0';
         ### at: "pos=$pos  v=$v"
         $v = Math::BigInt->from_bin($v);
         push @i, $seq->value_to_i_floor($v);
       }
       @i = sort {$a<=>$b} @i;
       ### i: scalar(@i)
       while (@i && @got < $count) {
         push @got, shift @i;
       }
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A346434',
   func => sub {
     my ($count) = @_;

     require Math::BigInt;
     my @got;
     for (my $c = 1; @got < $count; $c++) {
       my $str = ('10' x ($c-1)) . '1';
       ### $str
       my @i;
       for (my $pos = 1; $pos <= length($str); $pos += 2) {
         my $v = $str;
         substr($v,$pos,0) = '0';
         ### at: "pos=$pos  v=$v"
         push @i, Math::BigInt->new($v);
       }
       @i = sort {$a<=>$b} @i;
       while (@i && @got < $count) {
         push @got, shift @i;
       }
     }
     return \@got;
   });


#---------------------
# A346434 -- triangle all numbers with n 1s and n 0s in Zeckendorf,
# as decimal digits

# GP-DEFINE  \\ mine, written in decimal digits, compact
# GP-DEFINE  A346434_T(n,k) = {
# GP-DEFINE    n>=1 || error();
# GP-DEFINE    (1<=k && k<=n) || error();
# GP-DEFINE    (10*100^n - 9*100^(n-k))\99;
# GP-DEFINE  }
# GP-Test  my(v=OEIS_data("A346434"),got=[]); \
# GP-Test  for(n=1,oo, for(k=1,n, \
# GP-Test    if(#got>=#v,break(2)); got=concat(got,A346434_T(n,k)))); \
# GP-Test  got==v
# GP-Test  /* whole row in data, triangular number */ \
# GP-Test  my(len=#OEIS_data("A346434"),n); \
# GP-Test    ispolygonal(len,3,&n) && Triangular(n) == len
# GP-Test  vector(50,n, vector(n,k, A346434_T(n,k))) == \
# GP-Test  vector(50,n, vector(n,k, \
# GP-Test                  fromdigits(Zeckendorf_digits(A210619_Zeckendorf_euqal_0s1s_T(n,k)))))
# GP-Test  my(nk=3); (100^nk - 1)/99 == 010101
#
# cf ~/OEIS/b210619.txt is 49 rows to 1225, size 23853
#    ~/OEIS/b346434.txt size 87093
# system("rm                             /tmp/new/b346434.txt"); \
# my(c=0); for(n=1,49, for(k=1,n, write("/tmp/new/b346434.txt",c++," ",A346434_T(n,k)))); \
# system("ls -l                          /tmp/new/b346434.txt");
#   ,'bfile
# GP-Test  my(v=OEIS_data("A346434"),got=[]); \
# GP-Test    print("~/OEIS/b346434.txt size "#v); \
# GP-Test    for(n=1,oo, \
# GP-Test      got=concat(got,vector(n,k,A346434_T(n,k))); \
# GP-Test      if(#got>=#v, print("  which is rows 1..",n); break)); \
# GP-Test    got==v
#
# GP-DEFINE  vector_reps(v,n) = if(n==0,[], concat(vector(n,i,v)));
# GP-Test  /* comment 10s and 01s */ \
# GP-Test  vector(5,n, vector(n,k, A346434_T(n,k))) == \
# GP-Test  vector(5,n, vector(n,k, \
# GP-Test    fromdigits(concat(vector_reps([1,0],k), vector_reps([0,1],n-k)))))
#
# GP-Test  /* formula */ \
# GP-Test  vector(50,n, vector(n,k, A346434_T(n,k))) == \
# GP-Test  vector(50,n, vector(n,k, (10*100^n - 9*100^(n-k) - 1)/99 ))
#
# GP-Test  /* formula */ \
# GP-Test  vector(50,n, vector(n,k, A346434_T(n,k))) == \
# GP-Test  vector(50,n, vector(n,k, A014417_to_Zeckendorf(A210619_Zeckendorf_euqal_0s1s_T(n,k)) ))
# GP-Test  /* example table */ \
# GP-Test  my(n=1); vector(1,k, A346434_T(n,k)) == [ 10 ]
# GP-Test  my(n=2); vector(2,k, A346434_T(n,k)) == [ 1001,     1010 ]
# GP-Test  my(n=3); vector(3,k, A346434_T(n,k)) == [ 100101,   101001,   101010 ]
# GP-Test  my(n=4); vector(4,k, A346434_T(n,k)) == [ 10010101, 10100101, 10101001, 10101010 ]
# GP-Test  A346434_T(5,3) == 1010100101
#
# diagonal
# GP-DEFINE  A163662(n) = (10^(2*n) - 1)*10/99;
# GP-Test  my(v=OEIS_data("A163662")); /* OFFSET=1 */ \
# GP-Test    v == vector(#v,n, A163662(n))
# GP-Test  vector(50,n, A346434_T(n,n)) == \
# GP-Test  vector(50,n, A163662(n))
#
# GP-Test  /* prev row is *100 + 1 */ \
# GP-Test  vector(50,n,n++; vector(n-1,k, A346434_T(n,k))) == \
# GP-Test  vector(50,n,n++; vector(n-1,k, 100*A346434_T(n-1,k) + 1 ))

# GP-DEFINE  gA346434_limit(n_limit) = \
# GP-DEFINE    sum(n=1,n_limit, sum(k=1,n, A346434_T(n,k)*x^n*y^k));
# GP-Test  gA346434_limit(8) == 100*x*gA346434_limit(7) \
# GP-Test    + sum(n=1,8, (y-y^n)/(1-y)*x^n + (100^n-1)*10/99*x^n*y^n)
# GP-Test  my(k=5); (y-y^k)/(1-y) == y^4 + y^3 + y^2 + y
# GP-Test  my(n_limit=50, g=gA346434_limit(n_limit)); \
# GP-Test  matrix(n_limit,n_limit,n,k,n--;k--; gf2_term(g,n,k)) == \
# GP-Test  matrix(n_limit,n_limit,n,k,n--;k--; \
# GP-Test    if(n>=1 && k>=1 && k<=n, A346434_T(n,k)))

# GP-DEFINE  gA346434 = \
# GP-DEFINE    x*y*(10 - 9*x - 100*x^2*y) / ((1-x)*(1-100*x)*(1-x*y)*(1-100*x*y) );
# GP-Test  my(n_limit=50); \
# GP-Test  gA346434_limit(n_limit) == \
# GP-Test  gA346434 + O(x^(n_limit+1)) + O(y^(n_limit+1))
# GP-Test  my(n_limit=50); \
# GP-Test  matrix(n_limit,n_limit,n,k,n--;k--; gf2_term(gA346434,n,k)) == \
# GP-Test  matrix(n_limit,n_limit,n,k,n--;k--; \
# GP-Test    if(n>=1 && k>=1 && k<=n, A346434_T(n,k)))
#
# GP-Test  /* partial fractions, based on a y split */ \
# GP-Test  gA346434 == \
# GP-Test    -x/(1 - 101*x + 100*x^2) \
# GP-Test    - (10-109*x)/(99 - 9999*x + 9900*x^2)/(1 - x*y) \
# GP-Test    + 10/(99-9900*x)/(1-100*x*y)
#
# GP-Test  /* partial fractions, based on an x split */ \
# GP-Test  gA346434 == \
# GP-Test    -y/(99 - 99*y)/(1 - x) \
# GP-Test    + (991*y - y^2)/(9900 - 9999*y + 99*y^2)/(1 - 100*x) \
# GP-Test    + (109*y - 10*y^2)/(9900 - 9999*y + 99*y^2)/(1 - y*x) \
# GP-Test    - 10*y/(99 - 99*y)/(1 - 100*y*x)

# columns
# vector(6,n,n++; A346434_T(n,1))
# vector(6,n,n+=2; A346434_T(n,2))
# not in OEIS: 1001, 100101, 10010101, 1001010101, 100101010101, 10010101010101
# not in OEIS: 101001, 10100101, 1010010101, 101001010101, 10100101010101, 1010010101010101
#
# GP-Test  gf_terms(y*(10 - 9*y)/((1 - y)*(1 - 100*y)), 10) == \
# GP-Test  vector(10,n,n--; if(n<1,0, A346434_T(n,1)))
# recurrence_guess(vector(50,n,n--; if(n<5,0,A346434_T(n,5))))
#
# GP-DEFINE  gA346434_column(k) = {
# GP-DEFINE    k>=1 || error();
# GP-DEFINE    x^k * (x + (1-x)*(100^k-1)*10/99) /((1-x)*(1-100*x));
# GP-DEFINE  }
# GP-Test  gA346434_column(1) == x*(10 - 9*x)/((1 - x)*(1 - 100*x))
# GP-Test  my(limit=50); \
# GP-Test  vector(limit,k, gA346434_column(k)) == \
# GP-Test  vector(limit,k, sum(n=1,limit-1, \
# GP-Test     if(k<=n, A346434_T(n,k)*x^n)) + O(x^limit))

# row sums
# GP-Test  gf_terms(subst(gA346434,y,1),20) == \
# GP-Test  vector(20,n,n--; sum(k=1,n, A346434_T(n,k)))
# not in OEIS: 10, 2011, 302112, 40312213, 5041322314, 605142332415

# guessing columns y^n so x,y opposite way around
# recurrence_guess(vector(50,k,k--; if(k==0,0, subst_xy_swap(gA346434_column(k)))))
# subst_xy_swap(recurrence_guess_values_to_gf \
#   (vector(50,k,k--; if(k==0,0, subst_xy_swap(gA346434_column(k)))))) == \
# gA346434
# GP-DEFINE  subst_xy_swap(g) = {
# GP-DEFINE    g=subst(g,'x,'temporary);
# GP-DEFINE    g=subst(g,'x,'z);
# GP-DEFINE    g=subst(g,'y,'x);
# GP-DEFINE    subst(g,'temporary,'y);
# GP-DEFINE  }
# GP-Test  subst_xy_swap(x^5*y^3) == x^3*y^5
# recurrence_guess_INTERNAL_print_gf(gA346434)

# A/(99-9900*x) + B/(1-100*x*y) = 10/(99-9900*x)/(1-100*x*y)
# A*(1-100*x*y) + B*(99-9900*x) - 10 = 0
# A + 99*B = 10
# A = 10-99*B
# (10-99*B)*(1-100*x*y) + B*(99-9900*x) - 10 == ((9900*B - 1000)*y - 9900*B)*x
# 9900*y*B - 9900*B = 1000*y
# B*(9900*y - 9900) = 1000*y
# B = 10*y / (99*y - 99)

# for(n=1,8, for(k=1,n, print1(A346434_T(n,k),","));print());
# vector(20,n, A346434_T(n,1))
# not in OEIS: 10, 1001, 100101, 10010101, 1001010101, 100101010101, 10010101010101

# row sums
# vector(20,n,sum(k=1,n, A346434_T(n,k)))
# not in OEIS: 10, 2011, 302112, 40312213, 5041322314, 605142332415, 70615243342516

#------------------------------------------------------------------------------
# A134860 -- Wythoff AAB numbers is Zeck ending 101
# etc

foreach my $elem (
                  # Wythoff AB
                  # = Zeck ..10 plus 1
                  # = Zeck ..00 with even trailing 0s
                  # position of "1,0,1" pairs of 1s in Fibonacci word
                  ['A003623',  4, 2, offset=>1 ],
                  ['A003623',  4, 0, trailing0s => 0 ],

                  ['A134859',  8, 1],       # AAA
                  ['A134860',  8, 5],       # AAB
                  ['A134861', 16, 2],       # BAA
                  ['A134862', 16, 10, offset => 1 ],  # ABB
                  ['A134863', 16, 10],      # BAB
                  ['A134864', 32, 21, offset=>1 ],  # BBB
                  ['A151915', 16, 1],       # AAAA
                 ) {
  my ($anum, $modulus, $remainder, %option) = @$elem;
  MyOEIS::compare_values
      (anum => $anum,
       func => sub {
         my ($count) = @_;
         my $seq  = Math::NumSeq::Fibbinary->new;
         my @got;
         while (@got < $count) {
           my ($i, $value) = $seq->next;
           next if $value % $modulus != $remainder;
           if (defined $option{'trailing0s'}) {
             next unless $value;
             next if count_low_0_bits($value) % 2 != $option{'trailing0s'};
           }
           push @got, $i + ($option{'offset'}||0);
         }
         return \@got;
       });
}

sub count_low_0_bits {
  my ($n) = @_;
  if ($n <= 0) {
    return 0;
  }
  my $count = 0;
  until ($n % 2) {
    $count++;
    $n /= 2;
  }
  return $count;
}

#------------------------------------------------------------------------------
# A007895 -- num 1 bits = FibbinaryBitCount

MyOEIS::compare_values
  (anum => 'A007895',
   func => sub {
     my ($count) = @_;
     my $cnt = Math::NumSeq::DigitCount->new (digit => 1, radix => 2);
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $cnt->ith($value);
     }
     return \@got;
   });

# A102364 -- num 0 bits
MyOEIS::compare_values
  (anum => 'A102364',
   func => sub {
     my ($count) = @_;
     my $cnt = Math::NumSeq::DigitCount->new (digit => 0, radix => 2);
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $cnt->ith($value);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A104324 -- how many bit runs

MyOEIS::compare_values
  (anum => 'A104324',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, count_bit_runs($value);
     }
     return \@got;
   });

sub count_bit_runs {
  my ($n) = @_;
  my $count = 0;
  while ($n) {
    if ($n & 1) {
      do {
        $n >>= 1;
      } while ($n & 1);
      $count++;
    } else {
      do {
        $n >>= 1;
      } until ($n & 1);
      $count++;
    }
  }
  return $count;
}

#------------------------------------------------------------------------------
# A182636 Numbers whose Wythoff representation has odd length.
# A182637 Numbers whose Wythoff representation has even length.
# Zeck -> Wyth by 01 -> 1

MyOEIS::compare_values
  (anum => 'A182636',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       my $str = sprintf '%b', $value;
       $str =~ s/01/1/g;
       if (length($str) % 2 == 1) {
         push @got, $i+1;
       }
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A182637',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       my $str = sprintf '%b', $value;
       $str =~ s/01/1/g;
       if (length($str) % 2 == 0) {
         push @got, $i+1;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A118113 - 2*fibbinary+1

MyOEIS::compare_values
  (anum => 'A118113',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, 2*$value+1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A035514 - Zeckendorf Fibonnacis concatenated as decimal digits, high to low

MyOEIS::compare_values
  (anum => 'A035514',
   func => sub {
     my ($count) = @_;
     my $fibonacci  = Math::NumSeq::Fibonacci->new;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       my $concat = '';
       my $pos = 0;
       while ($value) {
         if ($value & 1) {
           $concat = $fibonacci->ith($pos+2) . $concat;
         }
         $value >>= 1;
         $pos++;
       }
       push @got, $concat || 0;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A035515 - Zeckendorf fibonnacis concatenated as decimal digits, low to high

MyOEIS::compare_values
  (anum => 'A035515',
   func => sub {
     my ($count) = @_;
     my $fibonacci  = Math::NumSeq::Fibonacci->new;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       my $concat = '';
       my $pos = 0;
       while ($value) {
         if ($value & 1) {
           $concat .= $fibonacci->ith($pos+2);
         }
         $value >>= 1;
         $pos++;
       }
       push @got, $concat || 0;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A035516 - Zeckendorf fibonnacis of each n, high to low
#           with single 0 for n=0

MyOEIS::compare_values
  (anum => 'A035516',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Repdigits;
     my $fibonacci  = Math::NumSeq::Fibonacci->new;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
   OUTER: for (;;) {
       my ($i, $value) = $seq->next;
       if ($value) {
         my @bits = Math::NumSeq::Repdigits::_digit_split_lowtohigh($value,2);
         foreach my $pos (reverse 0 .. $#bits) {
           if ($bits[$pos]) {
             push @got, $fibonacci->ith($pos+2);
             last OUTER if @got >= $count;
           }
         }
       } else {
         push @got, 0;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A035517 - Zeckendorf Fibonnaci terms, low to high
#           with single 0 for n=0

MyOEIS::compare_values
  (anum => 'A035517',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Repdigits;
     my $fibonacci  = Math::NumSeq::Fibonacci->new;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
   OUTER: for (;;) {
       my ($i, $value) = $seq->next;
       if ($value == 0) {
         push @got, 0;
         next;
       }
       # Fibbinary for Zeck bit flags
       my @bits = Math::NumSeq::Repdigits::_digit_split_lowtohigh($value,2);
       foreach my $pos (0 .. $#bits) {
         if ($bits[$pos]) {
           push @got, $fibonacci->ith($pos+2);
           last OUTER if @got >= $count;
         }
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A048680 - binary expand 1->01, then Fibbinary index of that value
# (permutation of the integers)

MyOEIS::compare_values
  (anum => 'A048680',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $expand = expand_1_to_01($n);
       my $fib_i = $seq->value_to_i_floor($expand);
       push @got, $fib_i;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# Lazy Zeckendorf to F(2)=1

# GP-DEFINE  lazy_fromdigits_terms(v) = vector(#v,i, if(v[i], fibonacci(#v-i+2), 0));

# A112309 lazy Fibonacci terms
# GP-Test  my(v=OEIS_data("A112309"), got=[], n=1); \
# GP-Test  while(#got<#v, \
# GP-Test    my(f=lazy_fromdigits_terms(lazy_digits(n))); \
# GP-Test    f=select(t->t!=0, Vecrev(f)); \
# GP-Test    got=concat(got,f); \
# GP-Test    n++); \
# GP-Test  got[1..#v] == v
# for(n=1,13, print(lazy11_fromdigits_terms(lazy_digits(n))))

# A095791 lazy Fibonacci num digits, wrongly taking 0 as one digit
# GP-Test  my(v=OEIS_data("A095791")); /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; #lazy_digits(n) + (n==0)) == v
# GP-Test  lazy_digits(1) == [1]
# GP-Test  lazy_digits(5) == [1,1,0]


#----------------------------

# GP-DEFINE  \\ map bits 0 -> 10 and 1s unchanged
# GP-DEFINE  make_no_00(n,base=10) = {
# GP-DEFINE    my(v=binary(n)[^1]);
# GP-DEFINE    if(#v==0,0,
# GP-DEFINE       for(i=1,#v, v[i]=if(v[i],[1],[1,0]));
# GP-DEFINE       fromdigits(concat(v),base));
# GP-DEFINE  }
# GP-Test  vector(6,n, make_no_00(n)) == [0, 10, 1, 1010, 101, 110]
# vector(10,n,n+=3; make_no_00(n))
# not in OEIS: 1010, 101, 110, 11, 101010, 10101, 10110, 1011, 11010, 1101
# vector(10,n,n+=3; make_no_00(n,2))
# not in OEIS: 10, 5, 6, 3, 42, 21, 22, 11, 26, 13
# GP-Test  my(limit=2^6, \
# GP-Test     m=vector(2*limit,n, make_no_00(n,2))); \
# GP-Test  m=select(n->n<limit,m); \
# GP-Test  vecsort(m) == select(is_A003754_nowhere_00,[0..limit])


#------------------------------------------------------------------------------
# Lazy Zeckendorf with Two F(1)=1 and F(2)=1

# GP-Test  vector(20,n,n--; sum(i=0,n-1,fibonacci(i))) == \
# GP-Test  vector(20,n,n--; fibonacci(n+1)-1)

# GP-DEFINE  lazy11_digits(n) = {
# GP-DEFINE    my(p=A130233_Zeckendorf_highpos(n)+2,l=List([]));
# GP-DEFINE    while(p>=1,
# GP-DEFINE      n>=0 || error();
# GP-DEFINE      \\ print("p="p" F="fibonacci(p)" n="n" cmp "fibonacci(p+1)-1);
# GP-DEFINE      listput(l, if(n<=fibonacci(p+1)-1, 0, n-=fibonacci(p);1));
# GP-DEFINE      p--);
# GP-DEFINE    n==0 || error(n);
# GP-DEFINE    while(#l&&l[1]==0,listpop(l,1));
# GP-DEFINE    Vec(l);
# GP-DEFINE  }
# GP-Test  lazy11_digits(1) == [1]
# GP-Test  lazy11_digits(2) == [1,1]
# GP-Test  lazy11_digits(3) == [1,0,1]
# GP-Test  lazy11_digits(4) == [1,1,1]
# GP-Test  lazy11_digits(5) == [1,0,1,1]
# GP-Test  lazy11_digits(6) == [1,1,0,1]
# GP-Test  lazy11_digits(7) == [1,1,1,1]
# GP-Test  7 == 1+1+2+3
# lazy11_fromdigits([1,1,1,0])
# lazy11_fromdigits([1,1,0,1])
# GP-DEFINE  to_lazy11(n) = fromdigits(lazy11_digits(n));


# GP-DEFINE  revlows(n) = {
# GP-DEFINE    my(v=concat(Zeckendorf_digits(n),[0]));
# GP-DEFINE    v=concat(v[1],Vecrev(v[^1]));
# GP-DEFINE    v[#v]==0||error();
# GP-DEFINE    Zeckendorf_fromdigits(v[^#v]);
# GP-DEFINE  }
# for(n=10,20, print(Zeckendorf_digits(n)," ",Zeckendorf_digits(revlows(n))))
# vector(20,n, revlows(n))
# select(n->n==revlows(n),[1..100])
# select(n->my(v=Zeckendorf_digits(n));v=v[3..#v]; v==Vecrev(v), [3..100])
# Zeckendorf_digits(14)
# Zeckendorf_digits(14)

# want = [1, 2, 3, 4, 5, 7, 6, 8, 11, 10, 9, 12, 13, 18, 16, 15, 20, 14, 19, 17, 21,\
# 29, 26, 24, 32, 23, 31, 28, 22, 30, 27, 25, 33, 34, 47, 42, 39, 52, 37,\
# 50, 45, 36, 49, 44, 41, 54, 35, 48, 43, 40, 53, 38, 51, 46, 55, 76, 68,\
# 63, 84, 60, 81, 73, 58, 79, 71, 66, 87]
# vector(#want,n,revlows(n)) == \
# want




# vector(20,n,fromdigits(lazy11_digits(n),2))
# vector(20,n,fromdigits(lazy11_digits(n)))
# A247647 Binary numbers that begin and end with 1 and do not contain two adjacent zeros.
# A247648 Numbers whose binary expansion begins and ends with 1 and does not contain two adjacent zeros.

# GP-DEFINE  lazy11_fromdigits_terms(v) = vector(#v,i, if(v[i], fibonacci(#v-i+1), 0));
# GP-DEFINE  lazy11_fromdigits(v) = vecsum(lazy11_fromdigits_terms(v));
# GP-Test  for(rep=1,1000, \
# GP-Test    my(len=random(256), \
# GP-Test       n=random(2^len), \
# GP-Test       v=lazy11_digits(n), \
# GP-Test       got=lazy11_fromdigits(v)); \
# GP-Test    if(got!=n, \
# GP-Test      print(n" "got); \
# GP-Test      print(v); \
# GP-Test      error()); \
# GP-Test  ); 1
# GP-Test  lazy11_fromdigits([1,1,1,1]) == 7

# GP-DEFINE  lazy11_revlows(n) = {
# GP-DEFINE    my(v=lazy11_digits(n));
# GP-DEFINE    v=Vecrev(v);
# GP-DEFINE    lazy11_fromdigits(v);
# GP-DEFINE  }
# want = [1, 2, 3, 4, 6, 5, 7, 8, 11, 10, 9, 12, 16, 14, 19, 13, 18, 17, 15, 20, 21,\
# 29, 27, 24, 32, 26, 23, 31, 22, 30, 28, 25, 33, 42, 37, 50, 35, 48, 45,\
# 40, 53, 34, 47, 44, 39, 52, 43, 38, 51, 36, 49, 46, 41, 54, 55, 76, 71,\
# 63, 84, 69, 61, 82, 58, 79, 74, 66, 87]
# vector(6,n,lazy11_revlows(n))
# vector(#want,n,lazy11_revlows(n)) == \
# want
# apply(n->fromdigits(Vecrev(lazy11_digits(n))),[13,14,15,16,17,18,19,20]) == \
# [110101,101101,111101,101011,111011,110111,101111,111111]

#------------------------------------------------------------------------------
# Zeckendorf Rotate
# vector(100,n, Zeckendorf_fromdigits(rot(Zeckendorf_digits(n))))

# vector(100,n, Zeckendorf_fromdigits(rot(Zeckendorf_digits(n))))

# GP-DEFINE  rotate_right(v) = if(#v<2,v,concat([v[#v]],v[1..#v-1]));
# GP-Test  rotate_right([10,20,30,40]) == [40, 10, 20, 30]
# GP-DEFINE  rotate_right_100(v) = if(#v>=2, until(v[1],v=rotate_right(v))); v;
# GP-Test  rotate_right_100([10,20,30,40,0,0]) == [40,0,0, 10, 20, 30]

# GP-DEFINE  \\ 10100100 -> 10001010       101 -> 101
# GP-DEFINE  \\     ^^^^    ^^^^            ^^    ^^
# GP-DEFINE  \\ rotate right low run 100 and one more 0 above it so always a
# GP-DEFINE  \\ 0 below the high 1
# GP-DEFINE  Zeck_rotate_right_100(v) = v=rotate_right_100(concat(v,0));v[^#v];
# GP-Test  Zeck_rotate_right_100([1,0,1,0,0,1,0]) == [1,0,0,1,0,1,0]
# GP-Test  Zeck_rotate_right_100([1,0]) == [1,0]
# vector(20,n, Zeckendorf_fromdigits(Zeck_rotate_right_100(Zeckendorf_digits(n))))
# not in OEIS: 1, 2, 3, 4, 5, 7, 6, 8, 11, 10, 9, 12, 13, 18, 16, 15, 19, 14, 20, 17

# GP-DEFINE  rotate_left(v) = if(#v<2,v,concat(v[2..#v],[v[1]]));
# GP-Test  rotate_left([10,20,30,40]) == [20, 30, 40, 10]
# GP-DEFINE  rotate_left_100(v) = if(#v>=2, until(v[1],v=rotate_left(v))); v;
# GP-Test  rotate_left_100([10,0,0,20,30,40]) == [20,30,40, 10,0,0]

# GP-DEFINE  Zeck_rotate_left_100(v) = if(#v<2,v, v=v[^2]; rotate_left_100(concat(v,0)));
# GP-Test  Zeck_rotate_left_100([1,0,1,0,0,1,0]) == [1,0,0,1,0,0,1]
# GP-Test  Zeck_rotate_left_100([1,0]) == [1,0]
# GP-Test  vector(1000,n,n--; my(v=Zeckendorf_digits(n)); Zeck_rotate_left_100(Zeck_rotate_right_100(v))) == \
# GP-Test  vector(1000,n,n--; my(v=Zeckendorf_digits(n)); v)
# GP-Test  vector(1000,n,n--; my(v=Zeckendorf_digits(n)); Zeck_rotate_right_100(Zeck_rotate_left_100(v))) == \
# GP-Test  vector(1000,n,n--; my(v=Zeckendorf_digits(n)); v)
# vector(20,n, Zeckendorf_fromdigits(Zeck_rotate_left_100(Zeckendorf_digits(n))))
# not in OEIS: 1, 2, 3, 4, 5, 7, 6, 8, 11, 10, 9, 12, 13, 18, 16, 15, 20, 14, 17, 19


#------------------------------------------------------------------------------
# Carlitz R(N) num representations

# A000119 Number of representations of n as a sum of distinct Fibonacci numbers.
# my(x=x+O(x^40)); gf_terms(lift(prod(n=2,20,1+x^fibonacci(n))),40)
# 1, 1, 1, 2, 1, 2, 2, 1, 3, 2, 2, 3, 1, 3, 3, 2, 4, 2, 3, 3
# cf A000121 with two 1s

# GP-DEFINE  e(n) = A005206_Hofstadter_G_shift_down(n);

# my(x=x+O(x^100), \
#    y=y+O(y^100), \
#    p = prod(n=1,20, 1 + x^fibonacci(n)*y^fibonacci(n+1)), \
#    A(m,n) = p=lift(p,'x); p=polcoeff(p,m,'x); \
#             p=lift(p,'y); polcoeff(p,n,'y)); \
# matrix(8,20,m,n, A(m,n))
# vector(20,n,n--; A(e(n), n))
# 1, 2, 2, 3, 3, 3, 4, 3, 4, 5, 4, 5, 4, 4, 6, 5, 6, 6, 5, 6, 4

# A(m,n) = if(m<0||n<0,0, m==0&&n==0, 1, A(n-m,n) + A(n-m,m-1));
# A(0,1)
# matrix(14,10,m,n, A(m,n))

# GP-DEFINE  e_indices(v,reps=1) = {
# GP-DEFINE    for(i=1,reps, v=apply(k->if(k<=0,error()); k-1, v));
# GP-DEFINE    v;
# GP-DEFINE  }
# GP-DEFINE  R(n) = R_of_indices(Zeckendorf_indices(n));
# GP-DEFINE  R_of_indices(v) = {
# GP-DEFINE    if(#v==0,return(1));
# GP-DEFINE    my(kr=v[#v]);
# GP-DEFINE    if(kr%2==1, return(R_of_indices(e_indices(v))));
# GP-DEFINE    my(t=kr/2, v1=v[^#v]);
# GP-DEFINE    R_of_indices(e_indices(v1,2*t-1))
# GP-DEFINE    + (t-1)*R_of_indices(e_indices(v1,2*t-2));
# GP-DEFINE  }
# GP-DEFINE  R_of_indices(v) = {
# GP-DEFINE    if(#v==0,return(1));
# GP-DEFINE    if(v[#v]%2==1, v=e_indices(v));
# GP-DEFINE    my(v1=v[^#v]);
# GP-DEFINE                  R_of_indices(e_indices(v1,v[#v]-1))
# GP-DEFINE    + (v[#v]/2-1)*R_of_indices(e_indices(v1,v[#v]-2));
# GP-DEFINE  }
# GP-Test  my(v=OEIS_data("A000119")); \
# GP-Test    vector(#v,n,n--; R(n)) == v
# vector(20,n,n--; R(n))
# R(13)

# GP-DEFINE  R_pair_by_digits(n) = {
# GP-DEFINE    my(v=Zeckendorf_digits(n+1),x=1,y=1,z=0);
# GP-DEFINE    for(i=1,#v,
# GP-DEFINE      \\ print("n="n"  x,y="x","y" zeck ",v[i]);
# GP-DEFINE      if(v[i], if(z, x+=y, x=y); z=0,
# GP-DEFINE               if(z, y+=x); z=!z));
# GP-DEFINE    [x,y];
# GP-DEFINE  }
# vector(2000,n, R_pair_by_digits(n)[1]) == \
# vector(2000,n, R(n))

# log(2)/log(phi)
# bestappr(log(2)/log(phi),50)
# log(2)/log(phi) * 32
# GP-DEFINE  R_pair(n) = {
# GP-DEFINE    n++;
# GP-DEFINE    my(k=floor(logint(n,2)*46>>5),x=1,y=1,z=0,f,g);
# GP-DEFINE    [f,g]=Vec(lift(Mod('x,'x^2-'x-1)^k));
# GP-DEFINE    while(g<n, [f,g]=[g,f+g]; print("n="n" k="k" up "f" "g));
# GP-DEFINE    while(f>n, [f,g]=[g-f,f]; print("down"));
# GP-DEFINE    while(g>=2,
# GP-DEFINE      \\ print("n="n" f="f" g="g"  x,y="x","y" zeck ",n>=f);
# GP-DEFINE      if(n>=f, if(z, x+=y, x=y); z=0; n-=f,
# GP-DEFINE               if(z, y+=x); z=!z);
# GP-DEFINE      [f,g]=[g-f,f]);
# GP-DEFINE    [x,y];
# GP-DEFINE  }
# my(n=17); print(R_pair(17)); print(R_pair_by_digits(17)); print([R(n),R(n+1)]); print(Zeckendorf_digits(n))
# vector(20,n, R_pair(n)[1])
# vector(20,n, R(n))


#------------------------------------------------------------------------------
# A095903 - Fibonacci terms by tree descents


#------
# A255773  tree lower Wythoff
#            0                  half of A095903
#         /    \
#       1        2              A255773 subtree 1 down
#     /  \      /  \            A255774 subtree 2 down
#   1+2  1+3  2+3  2+5

# GP-DEFINE  A255773(n) = {
# GP-DEFINE    my(x=0,y=0);
# GP-DEFINE    for(i=0,logint(n,2),
# GP-DEFINE       [x,y]=[y,x+y+1];
# GP-DEFINE       if(bittest(n,i), [x,y]=[y,x+y]));
# GP-DEFINE    y;
# GP-DEFINE  }
# GP-Test  my(v=OEIS_data("A255773")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, A255773(n)) == v
# GP-Test  /* formula */ \
# GP-Test  vector(1024,n, A255773(n)) == \
# GP-Test  vector(1024,n, A095903(A092754(n)))
#
# GP-Test  vector(1024,n, A255773(n)) == \
# GP-Test  vector(1024,n, A095903(insert_highbit(n,0)-1))
# GP-Test  vector(1024,n, A255773(n)) == \
# GP-Test  vector(1024,n, A095903(A004754_insert_high_0(n)-1))
# GP-Test  A095903(1) == 1
# GP-Test  A095903(2) == 2
# GP-Test  A095903(3) == 3

# GP-DEFINE  A255774(n) = {
# GP-DEFINE    my(x=0,y=0);
# GP-DEFINE    for(i=0,logint(n,2),
# GP-DEFINE       y++; [x,y]=[y,x+y];
# GP-DEFINE       if(bittest(n,i), [x,y]=[y,x+y]));
# GP-DEFINE    y;
# GP-DEFINE  }
# GP-Test  my(v=OEIS_data("A255774")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, A255774(n)) == v
# GP-Test  /* formula */ \
# GP-Test  vector(1024,n, A255774(n)) == \
# GP-Test  vector(1024,n, A095903(A206332(n)))
#
# GP-Test  vector(1024,n, A255774(n)) == \
# GP-Test  vector(1024,n, A095903(insert_highbit(n,1)-1))
# GP-Test  vector(1024,n, A255774(n)) == \
# GP-Test  vector(1024,n, A095903(A004755_insert_high_0(n)-1))


#------
# A345253  Fib tree = A095903+1

# GP-DEFINE  A345253(n) = {
# GP-DEFINE    my(ret=1,t=1);
# GP-DEFINE    forstep(i=logint(n,2)-1,0,-1, t+=1+bittest(n,i); ret+=fibonacci(t)); ret;
# GP-DEFINE  }
# GP-DEFINE  A345253_indices(n) = \
# GP-DEFINE    concat(1,if(n==1,[],A095903_indices(n-1)));
# GP-Test  A345253_indices(1) == [1]
# GP-Test  A345253_indices(2) == [1,2]
# GP-Test  A345253_indices(3) == [1,3]
# GP-Test  vector(1024,n, vecsum(apply(fibonacci,A345253_indices(n)))) == \
# GP-Test  vector(1024,n, A345253(n))

# GP-DEFINE  \\ like A095903 and final +1
# GP-DEFINE  A345253_by_plus1(n) = {
# GP-DEFINE    my(x=0,y=0);
# GP-DEFINE    for(i=0,logint(n,2)-1,
# GP-DEFINE       y++; [x,y]=[y,x+y];
# GP-DEFINE       if(bittest(n,i), [x,y]=[y,x+y]));
# GP-DEFINE    y+1;
# GP-DEFINE  }
# GP-Test  vector(1024,n, A345253_by_plus1(n)) == \
# GP-Test  vector(1024,n, A345253(n))

#                              1 2 3 5 8 13
# GP-Test  A345253(16)   == 1 +1+2+3+5
# GP-Test  A345253(16+8) == 1   +2+3+5+8
# GP-Test  A345253(16+1) == 1 +1+2+3  +8
# GP-Test  apply(fibonacci,[-3,-2,-1, 0, 1, 2]) == \
# GP-Test                  [ 2,-1, 1, 0, 1, 1]

# GP-DEFINE  A345253_by_all(n) = {
# GP-DEFINE    my(x=0,y=0);
# GP-DEFINE    for(i=0,logint(n,2),
# GP-DEFINE       [x,y]=if(bittest(n,i),[x+y,x+2*y+1],[y+1,x+y]));
# GP-DEFINE    y;
# GP-DEFINE  }
# GP-DEFINE  A345253_by_all(n) = {
# GP-DEFINE    my(x=0,y=0);
# GP-DEFINE    for(i=0,logint(n,2),
# GP-DEFINE       if(bittest(n,i),x+=y;y+=x+1,[x,y]=[y+1,x+y]));
# GP-DEFINE    y;
# GP-DEFINE  }
# GP-DEFINE  A345253_by_all(n) = {
# GP-DEFINE    my(x=0,y=0);
# GP-DEFINE    for(i=0,logint(n,2),
# GP-DEFINE       [x,y]=[y+1,x+y];
# GP-DEFINE       if(bittest(n,i), [x,y]=[y,x+y]));
# GP-DEFINE    y;
# GP-DEFINE  }
# GP-Test  vector(1024,n, A345253_by_all(n)) == \
# GP-Test  vector(1024,n, A345253(n))

# gettime(); for(n=1,100000,A345253(n));        gettime()
# gettime(); for(n=1,100000,A345253_by_all(n)); gettime()
# n=random(2^20000);
# n=(2^20000);
# gettime(); u=A345253(n);        print(gettime()); \
# gettime(); v=A345253_by_all(n); print(gettime()); \
# u==v


#------
# A232640 duplicates deleted
# A232641 Fibs opposite way bits ?, inverse of A232640


#------------------------------------------------------------------------------

# select(n-> (A072649_Zeckendorf_highpos_sub1(n-1) - A072649_Zeckendorf_highpos_sub1(n - A130312_Zeckendorf_F_below_high(n-1) - 1)) % 2, [3..100])
# vector(100,n,n++; (A072649_Zeckendorf_highpos_sub1(n-1) - A072649_Zeckendorf_highpos_sub1(n - A130312_Zeckendorf_F_below_high(n-1) - 1)) % 2)


#------------------------------------------------------------------------------
# Stolarsky digits

# select(n->Stolarsky_digits(n)[2]==1, [3..40])
# select(n->Stolarsky_digits(n)[2]==0, [3..40])
#  vector(200,n,n+=2; Stolarsky_digits(n)[2])
#  vector(200,n,n+=2; my(v=Stolarsky_digits(n)); v[#v])
#  vector(200,n,n+=2; my(v=Stolarsky_digits(n)); v[#v-1])

# vector(100,n,n+=2; (A072649_Zeckendorf_highpos_sub1(n-1) - A072649_Zeckendorf_highpos_sub1(n - A130312_Zeckendorf_F_below_high(n-1) - 1)) % 2) == \
# vector(100,n,n+=2; Stolarsky_digits(n)[2])

# GP-Test  vector(6,n, to_binary(A200714_Stolarsky(n))) == [0, 1, 11, 10, 111, 101]

# apply(n->Stolarsky_digits(n), [1,2,3,5,13,21,34,55,89])         \\ start 1
# apply(n->Stolarsky_digits(n), [4,6,10,16,26,42,68,110,178])     \\ start 10
# apply(n->Stolarsky_digits(n), [7,11,18,29,47,76,123,119,322])   \\ start 110
# apply(n->Stolarsky_digits(n), [9,15,24,39,63,102,165,267,432])  \\ start 100
# apply(n->Stolarsky_digits(n), [12,19,31,50,81,131,212,343,555]) \\ start 1110
# apply(n->Stolarsky_digits(n), [14,23,37,60,97,157,254,411,665]) \\ start 1010


#------------------------------------------------------------------------------
# A348710 shorten each run 1s
# cf A175048 lengthen
#    A106151 shorten 0s

# GP-Test  A348710_shorten_run1s(1) == 0
# GP-Test  A348710_shorten_run1s(2) == 0
# GP-Test  Vec([4,5,6],0) == [4,5,6]  /* unchanged, not to empty */
# vector(200,n,n++; A348710_shorten_run1s(n))
# not in OEIS: 0, 0, 1, 0, 0, 2, 3, 0, 0, 0, 1, 4, 2, 6, 7
# GP-Test  vector(256,n,n--; A348710_shorten_run1s(n)) == \
# GP-Test  vector(256,n,n--; my(v=concat([0],binary(n)),t=1); \
# GP-Test                    for(i=2,#v, if(v[i-1]||!v[i], v[t++]=v[i])); \
# GP-Test                    fromdigits(Vec(v,t),2))
# GP-Test  my(want=OEIS_data("A348710")); /* OFFSET=0 */ \
# GP-Test  vector(#want,n,n--; A348710_shorten_run1s(n)) == want

# system("mkdir -p      /tmp/new"); \
# system("rm            /tmp/new/b348710.txt"); \
# for(n=0,10000, write("/tmp/new/b348710.txt",n," ",A348710_shorten_run1s(n))); \
# system("ls -l         /tmp/new/b348710.txt");
#   ,'bfile
# GP-Test  my(want=OEIS_data("A348710")); \
# GP-Test  print("~/OEIS/b348710.txt length ",#want); \
# GP-Test  vector(#want,n,n--; A348710_shorten_run1s(n)) == want

# GP-Test  /* my example */ \
# GP-Test  my(n=14551, want=787); \
# GP-Test  A348710_shorten_run1s(n) == want   && \
# GP-Test  to_binary(n)    == 111 000 11 0 1 0 111  && \
# GP-Test  to_binary(want) ==  11 000  1 0   0  11

# GP-Test  /* decrease is inverse of increase */ \
# GP-Test  vector(256,n,; A348710_shorten_run1s(A175048_lengthen_run1s(n))) == \
# GP-Test  vector(256,n,; n)

# GP-Test  for(k=1,256, \
# GP-Test    for(n=0,A175048_lengthen_run1s(k)-1, \
# GP-Test      A348710_shorten_run1s(n) != k  || error())); 1

# GP-Test  /* don't want 1 of 01 pair */ \
# GP-Test  vector(256,n, A348710_shorten_run1s(n)) == \
# GP-Test  vector(256,n, my(v=binary(n),keep=vector(#v)); \
# GP-Test    keep[1]=[]; \
# GP-Test    for(i=2,#v, keep[i] = if(v[i-1]==0 && v[i]==1, [], [v[i]])); \
# GP-Test    fromdigits(concat(keep),2))

# get 0 for any no-11 numbers, which is A003714 Fibbinary
# GP-Test  my(v=OEIS_data("A003714")); \
# GP-Test    select(n->A348710_shorten_run1s(n)==0, [0..v[#v]]) == v

# get 1 for any ending 11 and otherwise all single 1s
# GP-Test  my(v=OEIS_data("A213540")); \
# GP-Test    select(n->A348710_shorten_run1s(n)==1, [0..v[#v]]) == v
# GP-DEFINE  is_A213540(n) = bitand(n,n<<1) == 2;
# GP-Test  /* Charles Greathouse relating to Fibbinary */ \
# GP-Test  my(v=OEIS_data("A213540")); \
# GP-Test    apply(t->t*8+3, OEIS_data("A003714")[1..#v]) == v
# apply(to_binary, OEIS_data("A213540"))
# not in OEIS: 11, 1011, 10011, 100011, 101011, 1000011, 1001011, 1010011

# select(n->A348710_shorten_run1s(n)==2, [0..100])
# select(n->A348710_shorten_run1s(n)==3, [0..100])
# not in OEIS: 6, 13, 22, 38, 45, 70, 77, 86
# not in OEIS: 7, 23, 39, 71, 87

# bit length after reduction
# vector(15,n,n+=2; bitlength(A348710_shorten_run1s(n)))
# vector(15,n,n+=2; bitlength(A348710_shorten_run1s(n))+1)
# not in OEIS: 1, 0, 0, 2, 2, 0, 0, 0, 1, 3, 2, 3, 3, 0, 0
# not in OEIS: 2, 1, 1, 3, 3, 1, 1, 1, 2, 4, 3, 4, 4, 1, 1

#------------
# GP-DEFINE  \\ including lowest 0 -> 01 as if 00 extends below radix point
# GP-DEFINE  insert_00_to_010(n) = {
# GP-DEFINE    my(v=binary(n),s=3);
# GP-DEFINE    if(#v>1,
# GP-DEFINE      for(i=1,#v-1, if(!(v[i]||v[i+1]), v[i]=[0,1]));
# GP-DEFINE      if(v[#v]==0,v[#v]=[0,1]);
# GP-DEFINE      v=concat(v));
# GP-DEFINE    fromdigits(v,2);
# GP-DEFINE  }
# vector(16,n,n++; insert_00_to_010(n))
# vector(16,n,n++; insert_00_to_010(n)\2)
# not in OEIS: 5, 3, 21, 5, 13, 7, 85, 21, 21, 11, 53, 13, 29, 15, 341, 85
# not in OEIS: 2, 1, 10, 2, 6, 3, 42, 10, 10, 5, 26, 6, 14, 7, 170, 42
# vector(10,n,n++; to_binary(insert_00_to_010(n)))
# not in OEIS: 101, 11, 10101, 101, 1101, 111, 1010101, 10101, 10101, 1011
# vector(16,n,n++; to_binary(n))

# GP-Test-Last  /* Set of terms occurring are A247648 odd no 00 */ \
# GP-Test-Last  my(limit=2^12, \
# GP-Test-Last     m=vector(limit,n,n--; insert_00_to_010(n))); \
# GP-Test-Last  m=select(n->n<limit,m); \
# GP-Test-Last  Set(m) == select(is_A247648,[0..limit])
# Set(vector(1000,n,n++; insert_00_to_010(n)))[3..15]

# GP-Test  /* unchanged by insert single 1s */ \
# GP-Test  vector(256,n,n--; A348710_shorten_run1s(insert_00_to_010(n))) == \
# GP-Test  vector(256,n,n--; A348710_shorten_run1s(n))


#-------------
# A090077 In binary expansion of n: reduce contiguous blocks of 1's to 1.
# A090077 ,0,1,2,1,4,5,2,1,8,

# GP-DEFINE  \\ MSB always keep
# GP-DEFINE  A090077_run_1s_to_1(n) = {
# GP-DEFINE    my(v=binary(n),t=1);
# GP-DEFINE    for(i=2,#v, if(!(v[i-1]&&v[i]), v[t++]=v[i]));
# GP-DEFINE    fromdigits(Vec(v,t),2);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_data("A090077")); /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A090077_run_1s_to_1(n)) == v

# GP-Test  vector(1024,n, A090077_run_1s_to_1(n)) == \
# GP-Test  vector(1024,n, my(v=binary(n),keep=vector(#v)); \
# GP-Test    keep[1]=[1]; \
# GP-Test    for(i=2,#v, keep[i] = if(v[i-1]==1 && v[i]==1, [], [v[i]])); \
# GP-Test    fromdigits(concat(keep),2))

# GP-Test  vector(256,n, bitlength(A090077_run_1s_to_1(n))) == \
# GP-Test  vector(256,n, CountZeroBits(n) + A069010_CountRun1s(n))
# vector(12,n,n++; bitlength(A090077_run_1s_to_1(n)))
# not in OEIS: 2, 1, 3, 3, 2, 1, 4, 4, 4, 3, 3, 3

#------------------------------------------------------------------------------
# A347188
# product of count terms in Stolarsky representation
# a(n) = (1 + A200649_Stolarsky_CountOnes(n)) * a(n - A130312_Zeckendorf_F_below_high(n-1))

# GP-DEFINE  A347188(n) = {
# GP-DEFINE    my(ret=1);
# GP-DEFINE    while(n>1,
# GP-DEFINE      ret *= A200649_Stolarsky_CountOnes(n) + 1;
# GP-DEFINE      n -= A130312_Zeckendorf_F_below_high(n-1));
# GP-DEFINE    ret;
# GP-DEFINE  }
# GP-Test  my(v=OEIS_data("A347188")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, A347188(n)) == v
# GP-Test  vector(6,n, A347188(n)) == [1, 2, 6, 4, 24, 18]
# GP-Test  my(n=2); A347188(n-1) == 1

# GP-Test  vector(1000,n,n+=3; A347188(n)) == \
# GP-Test  vector(1000,n,n+=3; n-=2; my(ret=2); \
# GP-Test                 while(n>0, \
# GP-Test                   ret *= A200649_Stolarsky_CountOnes(n+2) + 1; \
# GP-Test                   n -= lazy_highterm(n)); \
# GP-Test                 ret)
# GP-Test  lazy_highterm(2) == 2
# GP-Test  lazy_highterm(1) == 1
# GP-Test  A200649_Stolarsky_CountOnes(0+2) + 1 == 2

# for(n=20,40, \
#    print(to_lazy(n)" "to_Stolarsky(n+2), \
#          "  ",hammingweight(lazy_digits(n)) - hammingweight(lazy_digits(n-1)), \
#          " ",A200649_Stolarsky_CountOnes(n+2) - A200649_Stolarsky_CountOnes(n+2-1)))

# GP-DEFINE  decimal_A820003_delete_01_to_0(n) = \
# GP-DEFINE    fromdigits(vector_collapse_01_to_0(digits(n)))
# my(n=12345678,ret=1, want=A347188(n)); \
# while(n>1, \
#   my(c=A200649_Stolarsky_CountOnes(n)); \
#   ret *= c+1; \
#   printf("%25s count %2d   %33s\n", \
#     to_Stolarsky(n+1), c, decimal_A820003_delete_01_to_0(to_lazy(n+1)-100+1)); \
#   n -= A130312_Zeckendorf_F_below_high(n-1));; \
# [ret,want, ret==want]
#
# for(n=12345678,12345678+3, \
#   my(s=Stolarsky_digits(n), \
#      l=vector_collapse_01_to_0(lazy_digits(n-1)));\
#   if(s!=l, printf("%8d %15s\n         %15s\n\n", n, s,l)))
# 

#   A347188(n) = {
#     n>=1 || error();
#     if(n==1,1,
#        (1 + A200649_Stolarsky_CountOnes(n))*self()(n - A130312_Zeckendorf_F_below_high(n-1)));
#   }
# GP-Test  my(v=OEIS_data("A347188")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, A347188(n)) == v

# GP-DEFINE  \\ return a vector of the terms multiplied to make A347188
# GP-DEFINE  A347188_terms(n) = {
# GP-DEFINE    my(l=List([]));
# GP-DEFINE    while(n>1, my(t=A130312_Zeckendorf_F_below_high(n-1)); listput(l,t); n-=t);
# GP-DEFINE    if(n,listput(l,n));
# GP-DEFINE    Vec(l);
# GP-DEFINE  }
# GP-Test  vector(1000,n, vecsum(A347188_terms(n))) == \
# GP-Test  vector(1000,n, n)
# concat(vector(12,n,n++; A347188_terms(n)))

# GP-DEFINE  A347188_indices(n) = {
# GP-DEFINE    my(l=List([]));
# GP-DEFINE    while(n>1,
# GP-DEFINE       my(i=A130233_Zeckendorf_highpos(n-1)-1);
# GP-DEFINE       listput(l,i);
# GP-DEFINE       n-=fibonacci(i));
# GP-DEFINE    if(n,listput(l,1)); Vec(l);
# GP-DEFINE  }
# GP-Test  vector(100,n, apply(fibonacci,A347188_indices(n))) == \
# GP-Test  vector(100,n, A347188_terms(n))
# (vector(8,n,n++; A347188_indices(n)))

# GP-DEFINE  A347188_digits(n) = {
# GP-DEFINE    my(v=A347188_indices(n), d=vector(v[1]));
# GP-DEFINE    for(i=1,#v, d[v[i]]++);
# GP-DEFINE    if(n>1, d[1]==2 || error());
# GP-DEFINE    Vecrev(d);
# GP-DEFINE  }
# (vector(8,n,n++; A347188_digits(n)))
# vector(17,n,n++; fromdigits(A347188_digits(n)))
# vector(17,n,n++; to_lazy(n))
# for(n=1,15,print(A347188_digits(n)))

# GP-DEFINE  \\ WRONG
# GP-DEFINE  A347188_product_1digits_above(n) = {
# GP-DEFINE    my(v=A347188_digits(n),t=0);
# GP-DEFINE    if(v[#v]==2, v=concat(v[^#v],[1,1]));
# GP-DEFINE    prod(i=1,#v, t+=v[i]);
# GP-DEFINE  }
# v=sele
# vector(17,n,n++; A347188_product_1digits_above(n))
# vector(17,n,n++; A347188(n))

#------------------------------------------------------------------------------
# A820001 change 0 -> 01

# GP-DEFINE  \\ A820001 compact
# GP-DEFINE  my(rep=[[0,1],[1]]); \
# GP-DEFINE  A820001_insert_0_to_01(n) = \
# GP-DEFINE    if(n==0,0, fromdigits(concat([rep[b+1]|b<-binary(n)]),2));
# GP-Test  A820001_insert_0_to_01(0) == 0
# GP-Test  A820001_insert_0_to_01(1) == 1
# GP-Test  to_binary(A820001_insert_0_to_01(4)) == 10101
# vector(10,n,n+=2; to_binary(A820001_insert_0_to_01(n)))
# not in OEIS: 11, 10101, 1011, 1101, 111, 1010101, 101011, 101101, 10111, 110101
# vector(10,n,n+=2; A820001_insert_0_to_01(n))
# not in OEIS: 3, 21, 11, 13, 7, 85, 43, 45, 23, 53
#
# GP-Test  /* similar to compact form */ \
# GP-Test  vector(1000,n,n--; A820001_insert_0_to_01(n)) == \
# GP-Test  vector(1000,n,n--; \
# GP-Test     my(v=binary(n)); \
# GP-Test     for(i=1,#v, v[i]=if(v[i],[1],[0,1])); \
# GP-Test     if(#v,v=concat(v)); \
# GP-Test     fromdigits(v,2))
#
# GP-Test  /* hairy pre-calculation of vector length */ \
# GP-Test  vector(1000,n,n--; A820001_insert_0_to_01(n)) == \
# GP-Test  vector(1000,n,n--; \
# GP-Test     my(k=if(n,logint(n,2),-1), \
# GP-Test        v=vector(2*k+2-hammingweight(n)),p=0); \
# GP-Test     forstep(i=k,0,-1, v[p+=2-bittest(n,i)] = 1); \
# GP-Test     fromdigits(v,2))

# GP-Test-Last  /* sorted terms are A247648 */ \
# GP-Test-Last  my(limit=2^12, \
# GP-Test-Last     m=vector(limit,n,n--; A820001_insert_0_to_01(n))); \
# GP-Test-Last  m=select(n->n<limit,m); \
# GP-Test-Last  vecsort(m) == select(is_A247648,[0..limit])

# fixed points are 2^k-1 A000225
# GP-Test  select(n->A820001_insert_0_to_01(n)==n,[0..2^10]) == \
# GP-Test  vector(11,k,k--; 2^k-1)

# vector(12,n,n+=2; Zeckendorf_fromdigits(binary(A820001_insert_0_to_01(n))))
# not in OEIS: 3, 12, 8, 9, 6, 33, 21, 22, 14, 25, 16, 17
# GP-Test  Zeckendorf_fromdigits([1,1]) == 2 + 1
# GP-Test  Zeckendorf_fromdigits([1,0,0,0,1]) == 8 + 1

#------------------------------------------------------------------------------
# A820002 insert change 01 -> 011
#   smallest which A820003_delete_01_to_0 collapses to given n

#   A820002_insert_01_to_011(n) = \
#     if(n==0,0, fromdigits(concat([rep[b+1]|b<-binary(n)]),2));

# GP-DEFINE  my(table=[[1,0],[3,[1,1]], [1,0],[3,1]]); \
# GP-DEFINE  A820002_insert_01_to_011(n) = {
# GP-DEFINE    my(v=binary(n),s=3);
# GP-DEFINE    if(#v>2, for(i=2,#v, [s,v[i]]=table[s+v[i]]); v=concat(v));
# GP-DEFINE    fromdigits(v,2);
# GP-DEFINE  }
# GP-Test  A820002_insert_01_to_011(2) == 2
# GP-Test  A820002_insert_01_to_011(10) == from_binary(10110)
# GP-Test  A820002_insert_01_to_011(5) == from_binary(1011)
# vector(12,n,n+=2; A820002_insert_01_to_011(n))
# not in OEIS: 3, 4, 11, 6, 7, 8, 19, 22, 23, 12, 27, 14

# GP-Test  /* making new vector of new bits */ \
# GP-Test  vector(1000,n,n--; A820002_insert_01_to_011(n)) == \
# GP-Test  vector(1000,n,n--; \
# GP-Test     my(v=binary(n)); \
# GP-Test     c=vector(#v,i, if(i>1 && v[i-1]==0 && v[i]==1, [1,1], [v[i]])); \
# GP-Test     if(#c,c=concat(c));; \
# GP-Test     fromdigits(c,2))

# GP-Test  /* versus lengthening highest 1s too */ \
# GP-Test  vector(256,n, A175048_lengthen_run1s(n) \
# GP-Test              - A820002_insert_01_to_011(n)) == \
# GP-Test  vector(256,n, 1<<bitlength(A820002_insert_01_to_011(n)))

# GP-Test-Last  vector(50,n,n--; A820002_insert_01_to_011(n)) == \
# GP-Test-Last  vector(50,n,n--; A820003_delete_01_to_0_inverses_by_search(n)[1])
#  vector(5,n, A820003_delete_01_to_0_inverses_by_search(n))

#------------------------------------------------------------------------------
# A820003 delete change 01 -> 0

# vector(10,n, to_binary(bitneg(bitnegimply(n,n>>1),bitlength(n))))
# GP-Test  vector(200,n,n--; A820003_delete_01_to_0(A820001_insert_0_to_01(n))) == \
# GP-Test  vector(200,n,n--; n)  /* inverse */

# GP-Test  /* where does k=38 occur */ \
# GP-Test  my(k=38); select(n->A820003_delete_01_to_0(n)==k,[1..8*4^bitlength(k)]) == \
# GP-Test    [78, 157, 174, 349]
# GP-Test  A820003_delete_01_to_0( 78) == 38
# GP-Test  A820003_delete_01_to_0(157) == 38
# GP-Test  A820003_delete_01_to_0(174) == 38
# GP-Test  A820003_delete_01_to_0(349) == 38
#
# GP-Test  from_binary( 1 0  01 1 1 0  ) == 78
# GP-Test  from_binary( 1 0  01 1 1 01 ) == 157
# GP-Test  from_binary( 1 01 01 1 1 0  ) == 174
# GP-Test  from_binary( 1 01 01 1 1 01 ) == 349

# GP-DEFINE  A820003_delete_01_to_0_inverses_by_search(k) = {
# GP-DEFINE    my(l=List([]));
# GP-DEFINE    for(n=0,4^bitlength(k), if(A820003_delete_01_to_0(n)==k,listput(l,n)));
# GP-DEFINE    Vec(l);
# GP-DEFINE  }

# GP-DEFINE  \\ how many 0 bits without a 1 immediately following
# GP-DEFINE  A820003_delete_01_to_0_inverses_countpos(k) = CountZeroBits(bitor(k,k<<1));
# vector(20,n,n+=3; A820003_delete_01_to_0_inverses_countpos(n))
# vector(20,n,n+=3; A820003_delete_01_to_0_inverses_countpos(n)+1)
# vector(20,n,n+=3; A820003_delete_01_to_0_inverses_countpos(n)+2)
# vector(20,n,n+=3; A820003_delete_01_to_0_inverses_countpos(n)-1)
# vector(20,n,n+=3; A820003_delete_01_to_0_inverses_countpos(n)-2)
# not in OEIS: 2, 0, 1, 0, 3, 1, 1, 0, 2, 0, 1, 0, 4, 2, 2, 1, 2, 0, 1, 0
# not in OEIS: 4, 2, 3, 2, 5, 3, 3, 2, 4, 2, 3, 2, 6, 4, 4, 3, 4, 2, 3, 2
# not in OEIS: 3, 1, 2, 1, 4, 2, 2, 1, 3, 1, 2, 1, 5, 3, 3, 2, 3, 1, 2, 1
# not in OEIS: 1, -1, 0, -1, 2, 0, 0, -1, 1, -1, 0, -1, 3, 1, 1, 0, 1, -1, 0, -1
# not in OEIS: -2, -1, -2, 1, -1, -1, -2, 0, -2, -1, -2, 2, 0, 0, -1, 0, -2, -1, -2
# GP-Test  vector(256,n,n--; A820003_delete_01_to_0_inverses_countpos(n)) == \
# GP-Test  vector(256,n,n--; if(n,logint(n,2)+2) - hammingweight(bitor(n,n<<1)))
# GP-Test  vector(256,n,n--; A820003_delete_01_to_0_inverses_countpos(n)) == \
# GP-Test  vector(256,n,n--; if(n==0,0, A023416_CountZeroBits_z1(n) \
# GP-Test                               - A037800_Count01Pairs(n)))
# GP-Test  vector(256,n,n--; A820003_delete_01_to_0_inverses_countpos(n)) == \
# GP-Test  vector(256,n,n--; sum(i=0,if(n,logint(n,2),-1), bittest(n,i)==0 && bittest(n,i-1)==0))
# GP-Test  /* not same as count 00 bit pairs, since low bit 0 good here too */ \
# GP-Test  vector(256,n,n--; A820003_delete_01_to_0_inverses_countpos(n)) == \
# GP-Test  vector(256,n,n--; A056973_Count00Pairs(n) + (n>0 && n%2==0))
# vector(15,n,n+=3; 2^A023416_CountZeroBits_z1(n))

# GP-DEFINE  \\ 2^(number of 0's in binary representation of n)
# GP-DEFINE  \\ with n=0 as no bits
# GP-DEFINE  A080100(n) = 2^CountZeroBits(n);
# GP-Test  my(v=OEIS_data("A080100")); /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A080100(n)) == v

# GP-DEFINE  \\ 2^(num runs of 1s)
# GP-DEFINE  A277561(n) = 1<<hammingweight(bitnegimply(n,n>>1));
# GP-Test  my(v=OEIS_data("A277561")); /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A277561(n)) == v

# GP-DEFINE  A820003_delete_01_to_0_inverses_count(k) = \
# GP-DEFINE    1 << A820003_delete_01_to_0_inverses_countpos(k);
# GP-Test  A820003_delete_01_to_0_inverses_count(4) == 4
# vector(12,n,n+=2; A820003_delete_01_to_0_inverses_by_search(n))
# vector(12,n,n+=2; #A820003_delete_01_to_0_inverses_by_search(n))
# not in OEIS: 1, 4, 1, 2, 1, 8, 2, 2, 1, 4, 1, 2
# GP-Test  vector(32,n,n--; A820003_delete_01_to_0_inverses_count(n)) == \
# GP-Test  vector(32,n,n--; #A820003_delete_01_to_0_inverses_by_search(n))

# GP-DEFINE  \\ A292272, keep the 1-bit of each 01 pair, clear rest
# GP-DEFINE  one_of_each_01(n) = bitnegimply(n,n>>1);
# GP-Test  one_of_each_01(from_binary(1110011101)) == \
# GP-Test                 from_binary(1000010001)
# vector(12,n,n+=2; one_of_each_01(n))

# GP-DEFINE  complement_one_of_each_01(n) = bitneg(bitnegimply(n,n>>1),logint(n,2));
# vector(12,n,n+=2; complement_one_of_each_01(n))
# GP-Test  complement_one_of_each_01(from_binary(1110011101)) == \
# GP-Test                            from_binary( 111101110)
# not in OEIS: 1, 3, 2, 3, 3, 7, 6, 5, 5, 7, 6, 7
#
# vector(50,n,n+=2; bitand(complement_one_of_each_01(n),bitneg(n)))
# A035327 Write n in binary, interchange 0's and 1's, convert back to decimal.
# A035327 ,1,0,1,0,3,2

# GP-Test  A820003_delete_01_to_0(from_binary(111001111101)) == \
# GP-Test                   from_binary(11100 11110 )
# GP-Test  Vec([1,2,3],0) == [1,2,3]
# GP-Test  my(v=[1,2,3]); v[1..0] == []

# GP-Test  /* versus delete MSB too */ \
# GP-Test  vector(256,n, A820003_delete_01_to_0(n) \
# GP-Test              - A348710_shorten_run1s(n)) == \
# GP-Test  vector(256,n, 1<<logint(A820003_delete_01_to_0(n),2))


#------------------------------------------------------------------------------
# A247648 odd numbers no 00 bit pair

# GP-DEFINE  \\ A247648 = odd and nowhere bit pair 00
# GP-DEFINE  is_A247648(n) = \
# GP-DEFINE    n<<=1; n=bitneg(n,bitlength(n)); !bitand(n,n>>1);
# GP-Test  is_A247648(1) == 1
# GP-Test  is_A247648(2) == 0
# GP-Test  my(v=OEIS_data("A247648")); \
# GP-Test    select(is_A247648,[1..v[#v]]) == v

# GP-DEFINE  A247648(n) = {
# GP-DEFINE    n>=0 || error();
# GP-DEFINE    my(k=2);
# GP-DEFINE    while(fibonacci(k)<n,k++);
# GP-DEFINE    k-=0;
# GP-DEFINE    my(v=vector(k-1),prev=1);
# GP-DEFINE    for(i=1,#v,
# GP-DEFINE      \\ print("i="i" n="n" k="k" F="fibonacci(k));
# GP-DEFINE      if(n>=fibonacci(k),
# GP-DEFINE         prev=v[i]=1; n-=fibonacci(k-1);
# GP-DEFINE         \\ print("  bit "v[i]" sub "fibonacci(k-1)" to n="n);
# GP-DEFINE         ,
# GP-DEFINE         prev=0);
# GP-DEFINE      k--);
# GP-DEFINE    fromdigits(v,2);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_data("A247648")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, A247648(n)) == v
# GP-Test  my(v=select(is_A247648,[1..4096])); \
# GP-Test    vector(#v,n,A247648(n)) == v
#
# GP-Test  /* A247648 is a Fibonacci representation, ...,5,3,2,1,1 */ \
# GP-Test  vector(1024,n, my(t=A247648(n)); \
# GP-Test    sum(i=0,logint(t,2), if(bittest(t,i),fibonacci(i+1)))) == \
# GP-Test  vector(1024,n, n)

# GP-DEFINE  A247647(n) = to_binary(A247648(n));
# GP-Test  my(v=OEIS_data("A247647")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, A247647(n)) == v


# GP-DEFINE  \\ t is a term of A247648, return its index n
# GP-DEFINE  A247648_termpos(t) = {
# GP-DEFINE    is_A247648(t) || error();
# GP-DEFINE    sum(i=1,t, is_A247648(i));
# GP-DEFINE  }
#  vector(20,n, A247648_termpos(A820001_insert_0_to_01(n)))
#  vector(20,n, bitrev_sans_high(n))
#  vector(20,n, A348366(n))

# GP-Test  /* taking a 1 bit has F(k+2) terms below */ \
# GP-Test  vector(12,k,sum(n=0,2^k-1, is_A247648(n))) == \
# GP-Test  vector(12,k, fibonacci(k+2))

# A247648_xx(8)
# vector(10,n,n--; fromdigits(A247648_xx(n)))
# vector(10,n, to_binary(A247648(n)))
# vector(10,n, binary(A247648(n)))
# for(n=1,13,printf("%6d\n", to_binary(A247648(n))))
#      1  1
#     11  2
#    101  3
#    111  4
#   1011  5
#   1101  6
#   1111  7
#  10101  8     3  sub 5
#  10111  9
#  11011 10
#  11101 11
#  11111 12     7
# 101011


#--------
# A820004 permutation
# delete 1 after 0 of the A247648 odd numbers no 00 bit pair
#
# GP-DEFINE  A820004_del1no00(n) = A820003_delete_01_to_0(A247648(n));
# GP-Test  my(v=vector(5000,n, A820004_del1no00(n))); \
# GP-Test    #v == #Set(v)  /* no duplicates */

# GP-Test  /* is sort by bitlength_plus_0s(n) = A061313(n+1), */ \
# GP-Test  /* then numerically */ \
# GP-Test  my(v=vector(5000,n, A820004_del1no00(n))); \
# GP-Test    vecsort(v,bitlength_plus_0s) == v

# vector(15,n, A820004_del1no00(n))
# not in OEIS: 1, 3, 2, 7, 5, 6, 15, 4, 11, 13, 14, 31,  9, 10, 23, 12, 27, 29
# compare Stolarsky                                     vvvvvv
#           0, 1, 3, 2, 7, 5, 6, 15, 4, 11, 13, 14, 31, 10,  9, 23, 12, 27, 29

# vector(50,n, A820004_del1no00(n)) - \
# vector(50,n, A200714_Stolarsky(n+1))


#------------------------------------------------------------------------------
# A348366 something Fib bits reversed
#
# perm so A284005_product_count_1bits_above(a(n)) = A347188(n+1)
# A284005 = product each bit position how many 1-bits above
#
# A347188  a(n) = A346422(4*A003754(n-1) + 3) for n > 1 with a(1) = 1.
# a(n) = (1 + A200649_Stolarsky_CountOnes(n)) * a(n - A130312_Zeckendorf_F_below_high(n-1))
# A200649 = Stolarsky number of 1s

# GP-Test  my(l(n) = A072649_Zeckendorf_highpos_sub1(n+1)); \
# GP-Test  vector(100,n, l(n)) == \
# GP-Test  vector(100,n, if(n<2, n+1, l(n\((1+sqrt(5))/2)) + 1)) \
# GP-Test  && \
# GP-Test  vector(100,n, l(n-1)) == \
# GP-Test  vector(100,n, A072649_Zeckendorf_highpos_sub1(n))

# GP-Test  my(l(n) = A072649_Zeckendorf_highpos_sub1(n+1)); \
# GP-Test  my(f(n)=fibonacci(l(n))); \
# GP-Test  vector(100,n, f(n-1)) == \
# GP-Test  vector(100,n, A130312_Zeckendorf_F_below_high(n))

# GP-DEFINE  A348366_samps = {[
# GP-DEFINE    0, 1, 3, 2, 7, 6, 5, 15, 4, 14, 13, 11, 31, 12, 10, 30, 9,
# GP-DEFINE    29, 27, 23, 63, 8, 28, 26, 22, 62, 25, 21, 61, 19, 59, 55,
# GP-DEFINE    47, 127, 24, 20, 60, 18, 58, 54, 46, 126, 17, 57, 53, 45,
# GP-DEFINE    125, 51, 43, 123, 39, 119, 111, 95, 255, 16, 56, 52, 44,
# GP-DEFINE    124, 50, 42, 122, 38, 118 ]};
# apply(t->to_binary(bitrev_sans_high(t)), OEIS_data("A247648")[1..16])
# apply(t->to_binary(t), A348366_samps[1..17])
#
# GP-DEFINE  A348366(n) = {
# GP-DEFINE    if(n<2, n,
# GP-DEFINE       2*A348366(n - A130312_Zeckendorf_F_below_high(n))
# GP-DEFINE        + (A072649_Zeckendorf_highpos_sub1(n)
# GP-DEFINE           - A072649_Zeckendorf_highpos_sub1
# GP-DEFINE               (n - A130312_Zeckendorf_F_below_high(n))
# GP-DEFINE          ) % 2);
# GP-DEFINE  }
# GP-DEFINE  A348366 = memoize(A348366);
# GP-Test  vector(#A348366_samps,n,n--; A348366(n)) == \
# GP-Test          A348366_samps

# perm so A284005_product_count_1bits_above(a(n)) = A347188(n+1)
# GP-Test  vector(1000,n, A284005_product_count_1bits_above(A348366(n))) == \
# GP-Test  vector(1000,n, A347188(n+1))

# GP-DEFINE  second_highest_indices(n) = {
# GP-DEFINE    my(ret=List([]));
# GP-DEFINE    while(n>0,
# GP-DEFINE      my(l=A130233_Zeckendorf_highpos(n)-1);
# GP-DEFINE      n-=fibonacci(l);
# GP-DEFINE      listput(ret,l));
# GP-DEFINE    Vec(ret);
# GP-DEFINE  }
# GP-Test  second_highest_indices(2) == [2,1]
# GP-Test  second_highest_indices(3) == [3,1]

# GP-DEFINE  second_highest_terms(n) = apply(fibonacci,second_highest_indices(n));
# GP-Test  vector(100,n, vecsum(second_highest_terms(n))) == \
# GP-Test  vector(100,n, n)
# concat(vector(20,n, second_highest_terms(n)))
# concat(vector(20,n, Vecrev(second_highest_terms(n))))
# for(n=8,21, print(second_highest_terms(n)))

# GP-DEFINE  \\ high to low
# GP-DEFINE  second_highest_digits(n) = {
# GP-DEFINE    my(v=second_highest_indices(n), d=vector(vecmax(v)));
# GP-DEFINE    for(i=1,#v, d[v[i]]++);
# GP-DEFINE    Vecrev(d);
# GP-DEFINE  }
# GP-Test  second_highest_indices(5) == [4,2,1]
# GP-Test  second_highest_digits(5) == [1,0,1,1]
# concat(vector(16,n,n++; second_highest_digits(n)))
# concat(vector(16,n,n++; Vecrev(second_highest_digits(n))))
#
# GP-DEFINE  to_second_highest(n,base=10) = fromdigits(second_highest_digits(n),base);
# concat(vector(16,n,n++; to_second_highest(n)))

# GP-Test  my(v=vector(1000,n, to_second_highest(n,2))); \
# GP-Test    select(is_A247648,[1..v[#v]]) == v

# a(n)=if(n<2, n, 2*a(n - f(n-1)) + (l(n-1) - l(n - f(n-1) - 1))%2)
# l(n)=if(n<0,error()); if(n<2, n+1, l(n\((1+sqrt(5))/2)) + 1) \\ A072649_Zeckendorf_highpos_sub1(n+1)  highpos-1
# fib(n)=if(n<2, n, fib(n-1) + fib(n-2)) \\ A000045(n)
# f(n)=fib(l(n)) \\ A130312_Zeckendorf_F_below_high(n+1)
# vector(#A348366_samps,n,n--; a(n)) == A348366_samps

# GP-DEFINE  A348366_try(n,base=10) = {
# GP-DEFINE    my(v=second_highest_digits(n),l=List([1]));
# GP-DEFINE    forstep(i=#v,2,-1, if(v[i], listput(l,v[i-1])));
# GP-DEFINE    fromdigits(Vec(l),base);
# GP-DEFINE  }

# for(n=21,35, printf("%2d %25s %8d %8d %8d\n", \
#   n, second_highest_indices(n),to_binary(A348366(n)), try(n), to_second_highest(n)))

# GP-Test  vector(100,n, A348366(n)) == \
# GP-Test  vector(100,n, A348366_try(n,2))
# GP-Test  for(n=1,10000, A348366(n)==A348366_try(n,2) || error()); 1

# GP-Test  to_second_highest(5) == 1011
# GP-Test  fibonacci(4) + fibonacci(2) + fibonacci(1) == 5

# vector(10,n, to_lazy(n))
# vector(10,n, to_second_highest(n))

# GP-Test  /* odd sans 00 ones vs lazy ones */ \
# GP-Test  my(v=apply(hammingweight,select(is_A247648,[1..10000]))); \
# GP-Test  vector(#v,n, A112310_lazy_CountOnes(n-1)+1) == v
# apply(to_binary,select(is_A247648,[1..29]))
# vector(17,n,to_lazy(n))

#-------------------
# A348366 construct
# # Permutation of natural numbers such that A284005_product_count_1bits_above(a(n)) = A347188(n+1)
# whre A347188 falls in A284005

# GP-Test  /* made by A247648 values delete 1 after 0 */ \
# GP-Test  vector(10000,n, A348366(n)) == \
# GP-Test  vector(10000,n, bitrev_sans_high(A820003_delete_01_to_0(A247648(n))))
# GP-Test  vector(10000,n, A348366(n)) == \
# GP-Test  vector(10000,n, bitrev_sans_high(A820004_del1no00(n)))

# GP-DEFINE  A348366_key(n) = [bitlength_plus_0s(n),bitrev_sans_high(n)];
# Wrong: no sort order?  bitrev_sans_high of sorted values is only after
# the sort order has been applied.
#  /* made by sort */ \
#  my(v=vector(20,n, A348366(n))); \
#    vecsort(v,(n)-> [bitlength_plus_0s(n),bitrev_sans_high(n)]) - v
# GP-Test  apply(A348366,    [15,16]) == [30,9]
# GP-Test  apply(A348366_key,      [30,9]) == [[6,23], [6,12]]
# GP-Test  apply(bitrev_sans_high,  [30,9]) == [23, 12]
# GP-Test  apply(bitlength_plus_0s, [23,12]) == [6, 6]

#-------------------
# A348366 inverse

# GP-DEFINE  A348366_inv(n) = for(i=0,oo,if(A348366(i)==n,return(i)));
# GP-Test  vector(200,n,n--; A348366(A348366_inv(n))) == \
# GP-Test  vector(200,n,n--; n)
# vector(15,n, A348366_inv(n))
# not in OEIS: 1, 3, 2, 8, 6, 5, 4, 21, 16, 14, 11, 13, 10, 9, 7

# GP-Test  /* where in A247648 does insert1(bitrev_sans_high(n)) occur */ \
# GP-Test  vector(200,n, A348366_inv(n)) == \
# GP-Test  vector(200,n, A247648_termpos(A820001_insert_0_to_01(bitrev_sans_high(n))))


#------------------------------------------------------------------------------
# GP-DEFINE  Zeckendorf_shift_down_and_lowdigit(n) = {
# GP-DEFINE    \\ [floor((n+2)*(phi-1)) - 1,
# GP-DEFINE    \\  frac((n+1)*(2-phi)) > phi-1];
# GP-DEFINE    my(r); [n,r]=divrem(n+2,phi); [n-1,r>1];
# GP-DEFINE  }
# GP-Test  vector(1000,n,n++; Zeckendorf_shift_down_and_lowdigit(n)) == \
# GP-Test  vector(1000,n,n++; [A319433_Zeckendorf_shift_down(n), \
# GP-Test                      A003849_Zeckendorf_lowdigit(n)])

##------------------------------------------------------------------------------
# GP-DEFINE  Zeckendorf_CountLowZeros(n) = {
# GP-DEFINE    n>=0 || error();
# GP-DEFINE    my(q,r,ret=0);
# GP-DEFINE    if(n, while([q,r]=Zeckendorf_shift_down_and_lowdigit(n);r==0, n=q;ret++));
# GP-DEFINE    ret;
# GP-DEFINE  }
# GP-DEFINE  A035614_Whythoff_column(n) = {
# GP-DEFINE    n>=0 || error();
# GP-DEFINE    Zeckendorf_CountLowZeros(n+1);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_data("A035614")); /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A035614_Whythoff_column(n)) == v
#
# cumulative
# GP-Test  A035614_Whythoff_column(0) == 0
# vector(20,n, sum(i=0,n, A035614_Whythoff_column(i)))
# not in OEIS: 1, 3, 3, 6, 6, 7, 11, 11, 12, 14, 14, 19, 19, 20, 22, 22

# GP-Test  vector(20,k,k++; Zeckendorf_CountLowZeros(fibonacci(k))) == \
# GP-Test  vector(20,k,k++; k-2)


#------------------------------------------------------------------------------
# Binary Odd Part

# GP-DEFINE  A000265_oddpart(n) = n>>if(n,valuation(n,2));
# GP-Test  my(v=OEIS_data("A000265")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, A000265_oddpart(n)) == v

# GP-Test  my(v=OEIS_data("A004151")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, my(d=digits(n)); while(d[#d]==0,d=d[^#d]); fromdigits(d)) == v
# GP-Test  my(v=OEIS_data("A038502")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, my(d=digits(n,3)); while(d[#d]==0,d=d[^#d]); fromdigits(d,3)) == v
# my(b=4); vector(150,n, my(v=digits(n,b)); while(v[#v]==0,v=v[^#v]); fromdigits(v,b))
# A038502 ternary emove 3's from n.
# A065883 base 4


#------------------------------------------------------------------------------
# A349238 Zeckendorf Reverse

# GP-DEFINE  \\ A349238_Zeckendorf_reverse()
# GP-DEFINE  \\ A349239_Zeckendorf_reverse_add()
# GP-DEFINE  \\ A349240_Zeckendorf_reverse_sub()
# GP-DEFINE  previous_recover=default(recover);
#  iferr(read("../devel/a349238-Zeckendorf-reverse.gp"),e, \
#        read("devel/a349238-Zeckendorf-reverse.gp"));
# GP-DEFINE  default(recover,previous_recover);


#------------------------------------------------------------------------------
# A343150 Reverse the order of all but the most significant bits in the minimal Fibonacci expansion of n
# A343150 ,1,2,3,4,5,7,6,8,11,10,9,12,13

# GP-DEFINE  A343150_Zeckendorf_reverse_sanshigh(n) = {
# GP-DEFINE    n>=1 || error();
# GP-DEFINE    my(v=Zeckendorf_digits(n));
# GP-DEFINE    if(#v>2, v=concat(v[1..2],Vecrev(v[3..#v])));
# GP-DEFINE    Zeckendorf_fromdigits(v);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_data("A343150")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, A343150_Zeckendorf_reverse_sanshigh(n)) == v

# GP-Test  /* self-inverse */ \
# GP-Test  vector(1000,n, A343150_Zeckendorf_reverse_sanshigh( \
# GP-Test                  A343150_Zeckendorf_reverse_sanshigh(n))) == \
# GP-Test  vector(1000,n, n)

# GP-Test  /* append low 01 by "odd" so reverse becomes reverse excl high */ \
# GP-Test  vector(1000,n, A343150_Zeckendorf_reverse_sanshigh(n)) == \
# GP-Test  vector(1000,n, A019586_Wythoff_array_rownum0( \
# GP-Test                  A349238_Zeckendorf_reverse( \
# GP-Test                   A003622_Zeckendorf_odd(n+1))))

# GP-Test  /* append low 01 by "odd" so reverse becomes reverse excl high */ \
# GP-Test  vector(1000,n, A349238_Zeckendorf_reverse(n)) == \
# GP-Test  vector(1000,n, A003622_Zeckendorf_odd(1+ \
# GP-Test                  A066628_Zeckendorf_sans_highbit( \
# GP-Test                   A343150_Zeckendorf_reverse_sanshigh(n))))


#------------------------------------------------------------------------------
# A348571 starting points of new record num reverse+add steps to palindrome

# my(m=0,c=0); for(n=1,1000, my(t=Zeckendorf_Lychrel_steps(n)); \
#   if(t=='not,break); \
#   if(t>m,print(n"  steps "t"  ",Zeckendorf_Lychrel_trjaectory(n)); \
#          print("  ",apply(to_Zeckendorf,Zeckendorf_Lychrel_trjaectory(n))); \
#          m=t;if(c++>5,break)))



# LocalWords: Fibbinary
