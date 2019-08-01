#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2019 Kevin Ryde

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
use Test;
plan tests => 32;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099
use Math::NumSeq::Fibbinary;

# uncomment this to run the ### lines
# use Smart::Comments '###';


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
   # max_value => 100000,
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Palindromes;
     my $palindrome = Math::NumSeq::Palindromes->new (radix => 2);
     my $seq = Math::NumSeq::Fibbinary->new;
     my @got = (1,3);
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
# Permutations of 101010...10 which start with a 1, means position "00" at
# successively lower positions.

MyOEIS::compare_values
  (anum => 'A210619',
   # max_count => 20,
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

#------------------------------------------------------------------------------
# A123740 -- characteristic of Wythoff AB,
#   is second lowest bit of Zeck(n) -- or rather of n-1

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
# A014417 -- n in fibonacci base, the fibbinaries written out in binary

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
# A102364 -- num terms not used, how many zero bits

MyOEIS::compare_values
  (anum => 'A102364',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::DigitCount;
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
# A104324 -- how many bit runs, starting from n=1

MyOEIS::compare_values
  (anum => 'A104324',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Fibbinary->new;
     $seq->seek_to_i(1);
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
# A003622 - odd Zeckendorfs

MyOEIS::compare_values
  (anum => 'A003622',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value % 2) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A022342 - Zeckendorf even, i where value is even
#           floor(n*phi)-1
#           "Fibonacci successor"

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

#------------------------------------------------------------------------------
# A035514 - Zeckendorf fibonnacis concatenated as decimal digits, high to low

MyOEIS::compare_values
  (anum => 'A035514',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Fibonacci;
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
     require Math::NumSeq::Fibonacci;
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
     require Math::NumSeq::Fibonacci;
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
# A035517 - Zeckendorf fibonnacis of each n, low to high
#           with single 0 for n=0

MyOEIS::compare_values
  (anum => 'A035517',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Fibonacci;
     require Math::NumSeq::Repdigits;
     my $fibonacci  = Math::NumSeq::Fibonacci->new;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
   OUTER: for (;;) {
       my ($i, $value) = $seq->next;
       if ($value) {
         my @bits = Math::NumSeq::Repdigits::_digit_split_lowtohigh($value,2);
         foreach my $pos (0 .. $#bits) {
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
# A048678 - binary expand 1->01, so no adjacent 1 bits
# is a permutation of the fibbinary numbers

MyOEIS::compare_values
  (anum => 'A048678',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Fibbinary->new;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, expand_1_to_01($n);
     }
     return \@got;
   });

sub expand_1_to_01 {
  my ($n) = @_;
  my $bits = digit_split($n,2);  # $bits->[0] low bit
  @$bits = map {$_==0 ? (0) : (1,0)} @$bits;
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
# A048680 - binary expand 1->01, then fibbinary index of that value
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
exit 0;
