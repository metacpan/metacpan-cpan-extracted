#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

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
use Test;
use Math::BigInt;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $test_count = (tests => 2604)[1];
plan tests => $test_count;

# uncomment this to run the ### lines
# use Smart::Comments;


use POSIX ();
POSIX::setlocale(POSIX::LC_ALL(), 'C'); # no message translations

use constant DBL_INT_MAX => (POSIX::FLT_RADIX() ** POSIX::DBL_MANT_DIG());
use constant MY_MAX => (POSIX::FLT_RADIX() ** (POSIX::DBL_MANT_DIG()-5));

sub diff_nums {
  my ($gotaref, $wantaref) = @_;
  for (my $i = 0; $i < @$gotaref; $i++) {
    if ($i > @$wantaref) {
      return "want ends prematurely i=$i";
    }
    my $got = $gotaref->[$i];
    my $want = $wantaref->[$i];
    if (! defined $got && ! defined $want) {
      next;
    }
    if (! defined $got || ! defined $want) {
      return "different i=$i got=".(defined $got ? $got : '[undef]')
        ." want=".(defined $want ? $want : '[undef]');
    }
    if ($got != $want) {
      return "different i=$i numbers got=$got want=$want";
    }
  }
  return undef;
}

sub _delete_duplicates {
  my ($arrayref) = @_;
  my %seen;
  @seen{@$arrayref} = ();
  @$arrayref = sort {$a<=>$b} keys %seen;
}

sub _min {
  my $ret = shift;
  while (@_) {
    my $next = shift;
    if ($ret > $next) {
      $ret = $next;
    }
  }
  return $ret;
}

#------------------------------------------------------------------------------
my ($pos_infinity, $neg_infinity, $nan);
my ($is_infinity, $is_nan);
if (! eval { require Data::Float; 1 }) {
  MyTestHelpers::diag ("Data::Float not available");
} elsif (! Data::Float::have_infinite()) {
  MyTestHelpers::diag ("Data::Float have_infinite() is false");
} else {
  $is_infinity = sub {
    my ($x) = @_;
    return defined($x) && Data::Float::float_is_infinite($x);
  };
  $is_nan = sub {
    my ($x) = @_;
    return defined($x) && Data::Float::float_is_nan($x);
  };
  $pos_infinity = Data::Float::pos_infinity();
  $neg_infinity = Data::Float::neg_infinity();
  $nan = Data::Float::nan();
}
sub dbl_max {
  require POSIX;
  return POSIX::DBL_MAX();
}
sub dbl_max_neg {
  require POSIX;
  return - POSIX::DBL_MAX();
}

sub ternary {
  my ($str) = @_;
  my $ret = 0;
  foreach my $digit (split //, $str) { # high to low
    $ret = 3*$ret + $digit;
  }
  return $ret;
}

#------------------------------------------------------------------------------
# Math::NumSeq various classes

foreach my $elem
  (
   # DigitsModulo.pm
   # Expression.pm
   # Ln2Bits.pm
   # PiBits.pm

   [ 'Math::NumSeq::Xenodromes',
     [ 0 .. 9, 10, 12, 13 .. 19, 20, 21, 23, 24,
     ] ],

   [ 'Math::NumSeq::FibonacciRepresentations',
     [ 1, 1, 1, 2, 1, 2, 2, 1, 3, 2, 2, 3, 1, 3, 3, 2, 4, 2, 3, 3,
     ] ],

   [ 'Math::NumSeq::Pell',
     [ 0, 1, 2, 5, 12, 29, 70, 169, 408, 985, 2378, 5741,
       13860, 33461, 80782, 195025, 470832, 1136689,
     ] ],

   [ 'Math::NumSeq::LucasNumbers',
     [  1, 3, 4, 7, 11, 18, 29 ],
   ],
   [ 'Math::NumSeq::LucasNumbers',
     [  2, 1, 3, 4, 7, 11, 18, 29 ],
     { i_start => 0 },
   ],

   [ 'Math::NumSeq::Fibonacci',
     [ 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144,
       233, 377, 610, 987, 1597,
       '2584',
       '4181',
       '6765',
       '10946',
       '17711',
       '28657',
       '46368',
       '75025',
       '121393',
       '196418',
       '317811',
       '514229',
       '832040',
       # '1346269',
       # '2178309',
       # '3524578',
       # '5702887',
       # '9227465',
       # '14930352',
       # '24157817',
       # '39088169',
       # '63245986',
       # '102334155',
       # '165580141',
       # '267914296',
       # '433494437',
       # '701408733',
       # '1134903170',
       # '1836311903',
       # '2971215073',
       # '4807526976',
       # '7778742049',
       # '12586269025',
       # '20365011074',
       # '32951280099',
       # '53316291173',
       # '86267571272',
       # '139583862445',
       # '225851433717',
       # '365435296162',
       # '591286729879',
       # '956722026041',
       # '1548008755920',
       # '2504730781961',
       # '4052739537881',
       # '6557470319842',
       # '10610209857723',
       # '17167680177565',
       # '27777890035288',
       # '44945570212853',
       # '72723460248141',
       # '117669030460994',
       # '190392490709135',
       # '308061521170129',
       # '498454011879264',
       # '806515533049393',
       # '1304969544928657',
       # '2111485077978050',
       # '3416454622906707',
       # '5527939700884757',
       # '8944394323791464',
       # '14472334024676221',
     ] ],

   [ 'Math::NumSeq::SternDiatomic',
     [ 0, 1, 1, 2, 1, 3, 2, 3, 1, 4, 3, 5 ],
   ],

   [ 'Math::NumSeq::Abundant',
     [ 12, 18, 20, 24, 30 ],
   ],
   [ 'Math::NumSeq::Abundant',
     [ 1,2,3,4,5,7,8,9,10,11,13,14,15,16,17,19,21,22,23,25 ],
     { abundant_type => 'deficient' },
   ],
   [ 'Math::NumSeq::Abundant',
     [ 12,18,20,30,42,56,66,70,78,88,102,104,114,138,174,186 ],
     { abundant_type => 'primitive' },
   ],
   [ 'Math::NumSeq::Abundant',
     [ 24, 36, 40, 48, 54, 60, 72, 80, 84, 90, 96, 100, 108, 112, 120, 126, ],
     { abundant_type => 'non-primitive' },
   ],

   [ 'Math::NumSeq::PowerPart',
     [ 1,  # 1
       1,  # 2
       1,  # 3
       2,  # 4
       1,  # 5
       1,  # 6
       1,  # 7
       2,  # 8
     ]
   ],
   [ 'Math::NumSeq::PowerPart',
     [ 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1 ],
     { power => 3 },
   ],

   [ 'Math::NumSeq::PrimeFactorCount',
     [ 0,  # 1
       1,  # 2
       1,  # 3
       2,  # 4
       1,  # 5
       2,  # 6
       1,  # 7
       3,  # 8
     ],
   ],
   [ 'Math::NumSeq::PrimeFactorCount',
     [ 0,  # 1
       1,  # 2
       1,  # 3
       1,  # 4
       1,  # 5
       2,  # 6
       1,  # 7
       1,  # 8
     ],
     { multiplicity => 'distinct' },
   ],

   [ 'Math::NumSeq::DivisorCount',
     [ 1,2,2,3,2,4,2 ] ],

   [ 'Math::NumSeq::LiouvilleFunction',
     [ 1,  # 1
       -1, # 2
       -1, # 3
       1,  # 4
       -1, # 5
       1,  # 6
       -1, # 7
       -1, # 8
     ],
   ],
   [ 'Math::NumSeq::LiouvilleFunction',
     [ 0,  # 1
       1,  # 2
       1,  # 3
       0,  # 4
       1,  # 5
       0,  # 6
       1,  # 7
       1,  # 8
     ],
     { values_type => '0,1' },
   ],
   [ 'Math::NumSeq::LiouvilleFunction',
     [ 1,  # 1
       0,  # 2
       0,  # 3
       1,  # 4
       0,  # 5
       1,  # 6
       0,  # 7
       0,  # 8
     ],
     { values_type => '1,0' },
   ],

   [ 'Math::NumSeq::HafermanCarpet',  # per pod
     [ 0,1,0,1,0,1,0,1,0, 0,1,0,1,0,1,0,1,0, 0,1,0,1,0,1,0,1,0, 0, ],
   ],
   [ 'Math::NumSeq::HafermanCarpet',  # per pod
     [ 1,1,1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1,1,1,0,1,0,1,0, ],
     { initial_value => 1 },
   ],
   [ 'Math::NumSeq::HafermanCarpet',  # per pod
     [ 1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,1,0,1,0,1, ],
     { inverse => 1 },
   ],

   [ 'Math::NumSeq::ProthNumbers',
     [ 3, 5, 9, 13, 17, 25, 33, 41, 49, 57, 65, 81, 97, 113, 129, 145,
       161, 177, 193, 209, 225, 241, 257, 289, 321, 353, 385, 417, 449, 481,
       513, 545, 577, 609, 641, 673, 705, 737, 769, 801, 833, 865, 897, 929,
       961, 993, 1025, 1089, 1153, 1217, 1281, 1345, 1409 ] ],

   [ 'Math::NumSeq::Fibbinary',
     [ 0x0,  #      0
       0x1,  #      1
       0x2,  #     10
       0x4,  #    100
       0x5,  #    101
       0x8,  #   1000
       0x9,  #   1001
       0xA,  #   1010
       0x10, #  10000
       0x11, #  10001
       0x12, #  10010
       0x14, #  10100
       0x15, #  10101
       0x20, # 100000
     ],
   ],
   [ 'Math::NumSeq::FibbinaryBitCount',
     [ 0, #      0
       1, #      1
       1, #     10
       1, #    100
       2, #    101
       1, #   1000
       2, #   1001
       2, #   1010
       1, #  10000
       2, #  10001
       2, #  10010
       2, #  10100
       3, #  10101
       1, # 100000
     ],
   ],

   [ 'Math::NumSeq::Multiples',
     [ 0, 2, 4, 6, 8, 10, 12 ],
     { multiples => 2 },
     { value_to_i_floor_below_first => -1 },
   ],
   [ 'Math::NumSeq::Multiples',
     [ 0*37, 1*37, 2*37, 3*37, 4*37, 5*37, 6*37 ],
     { multiples => 37 },
     { value_to_i_floor_below_first => -1 },
   ],

   [ 'Math::NumSeq::FibonacciWord',
     [ 0,1,
       0,
       0,1,
       0,1,0,
       0,1,0,0,1,
     ],
   ],
   [ 'Math::NumSeq::FibonacciWord',
     [ 1,0,2,2,1,0,2,2,1,1,0,2,1,1 ],
     { fibonacci_word_type => "dense" },
   ],

   [ 'Math::NumSeq::Triangular',
     [ 0, 1, 3, 6, 10, 15, 21 ] ],

   [ 'Math::NumSeq::Pronic',
     [ 0, 2, 6, 12, 20, 30, 42 ] ],

   [ 'Math::NumSeq::LuckyNumbers',
     [ 1, 3, 7, 9, 13, 15, 21, 25, 31, 33, 37, 43, 49, 51, 63, 67, 69, 73 ],
   ],

   [ 'Math::NumSeq::BalancedBinary',
     [ 2, 10, 12, 42, 44, 50, 52, 56, 170, 172, 178, ],
   ],

   [ 'Math::NumSeq::UndulatingNumbers', # with a!=b
     [ ternary(0),ternary(1),ternary(2),
       ternary(10),            ternary(12),
       ternary(20),ternary(21),
       ternary(101),             ternary(121),
       ternary(202),ternary(212),
       ternary(1010),              ternary(1212),
       ternary(2020),ternary(2121),
       ternary(10101),               ternary(12121),
       ternary(20202),ternary(21212),
     ],
     { radix => 3,
       including_repdigits => 0 },
   ],
   [ 'Math::NumSeq::UndulatingNumbers', # with a!=b
     [ ternary(0),ternary(1),ternary(2),
       ternary(10),ternary(11),ternary(12),
       ternary(20),ternary(21),ternary(22),
       ternary(101),ternary(111),ternary(121),
       ternary(202),ternary(212),ternary(222),
       ternary(1010),ternary(1111),ternary(1212),
       ternary(2020),ternary(2121),ternary(2222),
       ternary(10101),ternary(11111),ternary(12121),
       ternary(20202),ternary(21212),ternary(22222),
     ],
     { radix => 3 },
   ],
   [ 'Math::NumSeq::UndulatingNumbers', # with a!=b
     [ 0,1,2,3,4,5,6,7,8,9,
       10,12,13,14,15,16,17,18,19,
       20,21,23,24,25,26,27,28,29,
       30,31,32,34,35,36,37,38,39,
       40,41,42,43,45,46,47,48,49,
       50,51,52,53,54,56,57,58,59,
       60,61,62,63,64,65,67,68,69,
       70,71,72,73,74,75,76,78,79,
       80,81,82,83,84,85,86,87,89,
       90,91,92,93,94,95,96,97,98,
       101,121,131,141,151,161,171,181,191,
       202,212,232,242,252,262,272,282,292,
       303,313,323,343,353,363,373,383,393,
       404,414,424,434,454,464,474,484,494,
       505,515,525,535,545,565,575,585,595,
       606,616,626,636,646,656,676,686,696,
       707,717,727,737,747,757,767,787,797,
       808,818,828,838,848,858,868,878,898,
       909,919,929,939,949,959,969,979,989,
       1010,1212,1313,1414,1515,1616,1717,1818,1919,
     ],
     { including_repdigits => 0 },
   ],
   [ 'Math::NumSeq::UndulatingNumbers', # with a!=b
     [ 0x0,   # 0b0  = 0
       0x1,   # 0b1  = 1
       0x2,   # 0b10  = 2
       0x5,   # 0b101  = 5
       0xA,   # 0b1010  = 10
       0x15,  # 0b10101  = 21
       0x2A,  # 0b101010
       0x55,  # 0b1010101
       0xAA,  # 0b1010_1010
       0x155, # 0b1_0101_0101
     ],
     { radix => 2,
       including_repdigits => 0 },
   ],

   [ 'Math::NumSeq::DedekindPsiCumulative',
     [ 1, 4, 8, 14, 20, 32, 40, 52, 64, 82, 94, 118 ], # values in the POD
   ],

   [ 'Math::NumSeq::DedekindPsiSteps',
     [ 0,0,0,0,
       1, # 5 -> 5+1=6=2*3
       0, # 6 = 2*3
       1, # 7 -> 7+1=8
       0, # 8 = 2*2*2
       0, # 9 = 3*3
       1, # 10 = 2*5 -> 3*6 = 2*3*3
     ],
   ],


   [ 'Math::NumSeq::HappyNumbers',
     [ 1, 7, 10, 13, 19, 23 ], # per POD
   ],

   [ 'Math::NumSeq::HappySteps',
     [ 1, 9, 13, 8, 12, 17, 6, 13, 12, 2, ], # per POD
   ],
   [ 'Math::NumSeq::HappySteps',
     [ 1,  #    1
       2,  #   10
       3,  #   11
       2,  #  100
       3,  #  101
       3,  #  110
       4,  #  111
       2,  # 1000
     ],
     { radix => 2 },
   ],


   [ 'Math::NumSeq::DigitSumModulo',
     [ 0,  # 00
       1,  # 01
       1,  # 10
       2,  # 11,
       1,  # 100
       2,  # 101
       2,  # 110
       0,  # 111
       1,  # 1000
     ],
     { radix => 2, modulus => 3 } ],

   [ 'Math::NumSeq::AlgebraicContinued',
     [ 1,3,1,5,1,1,4,1,1,8,1,14,1,10,2,1,4,12,2,3,2,1,3 ],
   ],
   [ 'Math::NumSeq::AlgebraicContinued',
     [ 1,2,3,1,4,1,5,1,1,6,2,5,8,3,3,4,2,6,4,4,1,3,2,3 ],
     { expression => 'cbrt(3)' },
   ],

   [ 'Math::NumSeq::MobiusFunction',
     [ 1, -1, -1, 0, -1, 1, ],
   ],

   [ 'Math::NumSeq::Catalan',
     [ 1, 1, 2, 5, 14, 42, 132, 429, 1430, 4862, 16796, 58786, 208012,
       742900, ],
   ],
   [ 'Math::NumSeq::Catalan',
     [ 1, 1, 1, 5, 7, 21, 33, 429, 715, 2431, 4199, ],
     { values_type => 'odd' },
   ],

   [ 'Math::NumSeq::GolayRudinShapiro',
     [ 1,   # 0
       1,   # 1
       1,   # 10
       -1,  # 11
       1,   # 100
       1,   # 101
       -1,  # 110
       1,   # 111
       1,   # 1000
       1,   # 1001
       1,   # 1010
       -1,  # 1011
       -1,  # 1100
       -1,  # 1101
       1,   # 1110
       -1,  # 1111
       1,   # 10000
     ],
   ],
   [ 'Math::NumSeq::GolayRudinShapiro',
     [ 0,   # 0
       0,   # 1
       0,   # 10
       1,   # 11
       0,   # 100
       0,   # 101
       1,   # 110
       0,   # 111
       0,   # 1000
       0,   # 1001
       0,   # 1010
       1,   # 1011
       1,   # 1100
       1,   # 1101
       0,   # 1110
       1,   # 1111
       0,   # 10000
     ],
     { values_type => '0,1' },
   ],
   [ 'Math::NumSeq::GolayRudinShapiroCumulative',
     [ 1,  # 0
       2,  # 1
       3,  # 10
       2,  # 11
       3,  # 100
       4,  # 101
       3,  # 110
       4,  # 111
       5,  # 1000
       6,  # 1001
       7,  # 1010
       6,  # 1011
       5,  # 1100
       4,  # 1101
       5,  # 1110
       4,  # 1111
       5,  # 10000
     ],
   ],

   [ 'Math::NumSeq::RadixConversion',
     [ 0, 1, 10, 11, 100, 101, 110, 111, 1000, 1001, 1010, 1011, ], # per POD
   ],
   [ 'Math::NumSeq::RadixConversion',
     [ 0x0, 0x1, 0x10, 0x11, 0x100, 0x101, 0x110, 0x111,
       0x1000, 0x1001, 0x1010, 0x1011, ],
     { to_radix => 16 },
   ],
   [ 'Math::NumSeq::RadixConversion',
     [ 0,1,2,3,4,5, 6, 7, 8, 9,
       2,3,4,5,6,7, 8, 9,10,11,
       4,5,6,7,8,9,10,11,12,13, ],
     { from_radix => 10, to_radix => 2 },
   ],

   # [ 'Math::NumSeq::PrimesDigits',
   #   [ 2, 3, 5, 7, 1, 1, 1, 3, 1, 7, 1, 9, 2, 3, 2, 9, ],
   # ],
   # [ 'Math::NumSeq::PrimesDigits',
   #   [ 2, 3, 5, 7, 1, 1, 3, 1, 7, 1, 9, 1, 3, 2, 9, 2, ],
   #   { order => 'reverse' },
   # ],
   # [ 'Math::NumSeq::PrimesDigits',
   #   [ 2, 3, 5, 7, 1, 1, 1, 3, 1, 7, 1, 9, 2, 3, 2, 9,
   #     1, 3, 3, 7, 1, 4, 3, 4, 4, 7, 3, 5, ],
   #   { order => 'sorted' },
   # ],

   [ 'Math::NumSeq::DuffinianNumbers',
     [ 4,  # sumdiv=1+2=3
       8,  # sumdiv=1+2+4=7
       9,  # sumdiv=1+3=4
       16, # sumdiv=1+2+4+8=15
       21, # sumdiv=1+3+7=11
       25, # sumdiv=1+5=6
       27,
       32,
       35,
       36, # sumdiv=1+6=7
       39, 49, 50, 55, 57, 63, 64, 65,
     ]
   ],

   [ 'Math::NumSeq::PowerFlip',
     [ 1,  # 1
       1,  # 2^1 -> 1^2
       1,  # 3^1 -> 1^3
       4,  # 2^2 -> 2^2
       1,  # 5^1 -> 1^5
       1,  # 2^1*3^1 -> 1^2*1^3
       1,  # 7^1 -> 1^7
       9,  # 2^3 -> 3^2
     ],
   ],

   [ 'Math::NumSeq::DigitProductSteps',
     [ 0,0,0,0,0, 0,0,0,0,0,   # i=0 to 9
       1,1,1,1,1, 1,1,1,1,1,   # i=10 to 19
       1,1,1,1,1, 2,2,2,2,2,   # i=20 to 29
     ],
   ],
   [ 'Math::NumSeq::DigitProductSteps',
     [ 0,1,2,3,4, 5,6,7,8,9,   # i=0 to 9
       0,1,2,3,4, 5,6,7,8,9,   # i=10 to 19
       0,2,4,6,8, 0,2,4,6,8,   # i=20 to 29
     ],
     { values_type => 'root' },
   ],

   [ 'Math::NumSeq::MaxDigitCount',
     [ 0,   # i=1 no zeros ever
       1,   #   2 = 10 binary
       1,   #   3 = 10 ternary
       2,   #   4 = 100 binary
       1,   #   5 = 101 binary
       1,   #   6 = 110 binary
       1,   #   7 = 10 base7
       3,   #   8 = 1000 binary
       2,   #   9 = 1001 binary
       2,   #  10 = 1010 binary
     ],
   ],
   [ 'Math::NumSeq::MaxDigitCount',
     [ 2,   # i=1 no zeros ever
       2,   #   2 = 10 binary
       3,   #   3 = 10 ternary
       2,   #   4 = 100 binary
       2,   #   5 = 101 binary
       2,   #   6 = 110 binary
       7,   #   7 = 10 base7
       2,   #   8 = 1000 binary
       2,   #   9 = 1001 binary
       2,   #  10 = 1010 binary
     ],
     { values_type => 'radix' },
   ],

   [ 'Math::NumSeq::MaxDigitCount',
     [ 1,   # i=1 = 1 binary
       1,   #   2 = 10 binary
       2,   #   3 = 11 binary
       2,   #   4 = 11 ternary
       2,   #   5 = 101 binary
       2,   #   6 = 110 binary
       3,   #   7 = 111 binary
       2,   #   8 = 11 base7 binary
       2,   #   9 = 1001 binary
       2,   #  10 = 1010 binary
     ],
     { digit => 1 },
   ],
   [ 'Math::NumSeq::MaxDigitCount',
     [ 2,   # i=1 = 1 binary
       2,   #   2 = 10 binary
       2,   #   3 = 11 binary
       3,   #   4 = 11 ternary
       2,   #   5 = 101 binary
       2,   #   6 = 110 binary
       2,   #   7 = 10 base7
       7,   #   8 = 1000 binary
       2,   #   9 = 1001 binary
       2,   #  10 = 1010 binary
     ],
     { digit => 1,
       values_type => 'radix' },
   ],

   [ 'Math::NumSeq::AllPrimeFactors',
     [ 2, 3, 2,2, 5, 2,3, 7, 2,2,2, 3,3, 2,5, 11, ],
   ],
   [ 'Math::NumSeq::AllPrimeFactors',
     [ 2, 3, 2,2, 5, 3,2, 7, 2,2,2, 3,3, 5,2, 11, ],
     { order => 'descending' },
   ],
   [ 'Math::NumSeq::AllPrimeFactors',
     [ 2, 3, 2, 5, 2, 3, 7, 2, 3, 2, 5, 11, ],
     { multiplicity => 'distinct' },
   ],
   [ 'Math::NumSeq::AllPrimeFactors',
     [ 3, 5, 7, 3,3, 11, 13, 3,5, 17,, ],
     { on_values => 'odd' },
   ],
   [ 'Math::NumSeq::AllPrimeFactors',
     [ 2, 2,2, 2,3, 2,2,2, 2,5, 2,2,3, 2,7, 2,2,2,2, 2,3,3, 2,2,5, 2,11, ],
     { on_values => 'even' },
   ],
   [ 'Math::NumSeq::AllPrimeFactors',
     [ 2, 2, 2,3, 2, 2,5, 2,3, 2,7, 2, 2,3, 2,5, 2,11, ],
     { on_values => 'even',
       multiplicity => 'distinct' },
   ],

   [ 'Math::NumSeq::Repdigits',
     [ 0,
       1,2,3,4,5,6,7,8,9,
       11,22,33,44,55,66,77,88,99,
       111,222,333,444,555,666,777,888,999,
     ] ],
   [ 'Math::NumSeq::Repdigits',
     [ 0,
       01,02,03,04,05,06,07,
       011,022,033,044,055,066,077,
       0111,0222,0333,0444,0555,0666,0777, ],
     { radix => 8 },
   ],
   [ 'Math::NumSeq::Repdigits',
     [ 0, 1,2,
       4, # 11
       8, # 22
       13, # 111
       26, # 222
       40, # 1111
       80, # 2222
     ],
     { radix => 3 },
   ],
   [ 'Math::NumSeq::Repdigits',
     [ 0,
       1,  # 1
       3,  # 11
       7,  # 111
       15, # 1111
       31, # 11111
       63, # 111111
     ],
     { radix => 2 },
   ],

   [ 'Math::NumSeq::SpiroFibonacci',
     [ 0,1,1,1,1,1,1,1,2,3,4,5 ],
   ],

   [ 'Math::NumSeq::PrimeIndexOrder',
     [ 0, 1, 2, 0, 3, 0, 1, 0, 0, 0, 4, 0, 1, 0, 0, 0, 2, ],
   ],
   [ 'Math::NumSeq::PrimeIndexOrder',
     [ 1, 2, 3, 1, 4, 1, 2, ],
     { on_values => 'primes' },
   ],

   [ 'Math::NumSeq::PrimeIndexPrimes',
     [ 3, 5, 11, 17, 31, 41, 59, 67, 83, 109, 127, 157, 179, 191, ],
   ],
   [ 'Math::NumSeq::PrimeIndexPrimes',
     [ 2,3,5,7,11,13,17,19, ],
     { level => 1 }, # all primes
   ],
   [ 'Math::NumSeq::PrimeIndexPrimes',
     [ 1,2,3,4,5,6, ],
     { level => 0 }, # all integers
   ],
   [ 'Math::NumSeq::PrimeIndexPrimes',
     [ 3, 17, 41, 67, 83, 109, 157, 191, 211, 241, 283, 353, ],
     { level_type => 'exact' },
   ],
   [ 'Math::NumSeq::PrimeIndexPrimes',
     [ 2, 7, 13, 19, 23, 29, 37, 43, 47, 53, 61, 71, 73, 79, ],
     { level => 1,
       level_type => 'exact' },
   ],
   [ 'Math::NumSeq::PrimeIndexPrimes',
     [ 1,4,6,8,9,10,12,14, ],  # composites
     { level => 0,
       level_type => 'exact' },
   ],

   [ 'Math::NumSeq::GolombSequence',
     [ 1, 2,2, 3,3, 4,4,4, 5,5,5, 6,6,6,6, ],
   ],
   [ 'Math::NumSeq::GolombSequence',
     [ 1, 3,3,3, 5,5,5, 7,7,7, 9,9,9,9,9, ],
     { using_values => 'odd' },
   ],
   [ 'Math::NumSeq::GolombSequence',
     [ 2,2, 4,4, 6,6,6,6, 8,8,8,8, ],
     { using_values => 'even' },
   ],
   [ 'Math::NumSeq::GolombSequence',
     [ 3,3,3, 6,6,6, 9,9,9, 12,12,12,12,12,12, ],
     { using_values => '3k' },
   ],
   [ 'Math::NumSeq::GolombSequence',
     [ 1, 4,4,4,4, 9,9,9,9, 16,16,16,16, 25,25,25,25, ],
     { using_values => 'squares' },
   ],
   [ 'Math::NumSeq::GolombSequence',
     [ 2,2, 3,3, 5,5,5, 7,7,7, 11,11,11,11,11, ],
     { using_values => 'primes' },
   ],

   [ 'Math::NumSeq::ErdosSelfridgeClass',
     [ 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 2, 0, 0, 0, 1, 0, 2, 0, 0, ],
   ],
   [ 'Math::NumSeq::ErdosSelfridgeClass',
     [ 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 2, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, ],
     { p_or_m => '-' },
   ],
   [ 'Math::NumSeq::ErdosSelfridgeClass',
     [ 1, 1, 1, 1, 1, 2, 1, 2, 1, 2, 1, 3, 2, 2, 1, 1, 2, 2, 2, 1, 4, ],
     { on_values => 'primes' },
   ],

   [ 'Math::NumSeq::SelfLengthCumulative',
     [ 1, 2, 3, 4, 5,6,7,8, 9, 10, 12, 14, 16 ],
   ],
   [ 'Math::NumSeq::SelfLengthCumulative',
     [ 1, 2, 4, 7, 10, 14, 18, 23, 28, 33, 39, 45, ],
     { radix => 2 },
   ],

   [ 'Math::NumSeq::Runs',
     [ 0, 1, 2, 3, 4 ],
     { runs_type => '1rep' },
   ],
   [ 'Math::NumSeq::Runs',
     [ 0,0, 1,1, 2,2, 3,3, 4,4 ],
     { runs_type => '2rep' },
   ],
   [ 'Math::NumSeq::Runs',
     [ 0,0,0, 1,1,1, 2,2,2, 3,3,3 ],
     { runs_type => '3rep' },
   ],
   [ 'Math::NumSeq::Runs',
     [ 0,0,0,0, 1,1,1,1, 2,2,2,2, 3,3,3,3 ],
     { runs_type => '4rep' },
   ],
   [ 'Math::NumSeq::Runs',
     [ 0, 0,1, 0,1,2, 0,1,2,3 ],
     { runs_type => '0toN' },
   ],
   [ 'Math::NumSeq::Runs',
     [ 0, 0,1,2, 0,1,2,3,4, 0,1,2,3,4,5,6, 0,1,2,3,4,5,6,7,8, 0 ],
     { runs_type => '0to2N' },
   ],
   [ 'Math::NumSeq::Runs',
     [ 1, 1,2, 1,2,3 ],
     { runs_type => '1toN' },
   ],
   [ 'Math::NumSeq::Runs',
     [ 1,2, 1,2,3,4, 1,2,3,4,5,6 ],
     { runs_type => '1to2N' },
   ],
   [ 'Math::NumSeq::Runs',
     [ 1, 1,2,3, 1,2,3,4,5, 1,2,3,4,5,6,7 ],
     { runs_type => '1to2N+1' },
   ],
   [ 'Math::NumSeq::Runs',
     [ 1, 1, 1, 2, 1, 2, 3, 1, 2, 3, 4, 5, ],
     { runs_type => '1toFib' },
   ],
   [ 'Math::NumSeq::Runs',
     [ 0, 1,0, 2,1,0, 3,2,1,0, ],
     { runs_type => 'Nto0' },
   ],
   [ 'Math::NumSeq::Runs',
     [ 1, 2,1, 3,2,1, ],
     { runs_type => 'Nto1' },
   ],
   [ 'Math::NumSeq::Runs',
     [ 0, 1,2, 2,3,4, 3,4,5,6, ],
     { runs_type => '0toNinc' },
   ],
   [ 'Math::NumSeq::Runs',
     [ 1, 2,2, 3,3,3, 4,4,4,4, ],
     { runs_type => 'Nrep' },
   ],
   [ 'Math::NumSeq::Runs',
     [ 0, 1,1, 2,2,2, 3,3,3,3, ],
     { runs_type => 'N+1rep' },
   ],


   [ 'Math::NumSeq::MoranNumbers',
     [ 18, 21, 27, 42, 45, 63, 84, 111, 114, 117, 133, 152, 153, 156, ],
   ],

   [ 'Math::NumSeq::SophieGermainPrimes',
     [ 2, 3, 5, 11, 23, 29, 41, 53, 83, 89, 113, 131, 173,
       179, 191, 233, 239, 251, 281, 293, 359, 419, 431,
       443, 491, 509, 593, 641, 653, 659, 683, 719, 743,
       761, 809, 911, 953, 1013, 1019, 1031, 1049, 1103,
       1223, 1229, 1289, 1409, 1439, 1451, 1481, 1499,
       1511, 1559 ],
   ],

   # # http://oeis.org/A005385
   # [ 'Math::NumSeq::SafePrimes',
   #   [ 5, 7, 11, 23, 47, 59, 83, 107, 167, 179, 227, 263,
   #     347, 359, 383, 467, 479, 503, 563, 587, 719, 839,
   #     863, 887, 983, 1019, 1187, 1283, 1307, 1319, 1367,
   #     1439, 1487, 1523, 1619, 1823, 1907, 2027, 2039,
   #     2063, 2099, 2207, 2447, 2459, 2579, 2819, 2879, 2903,
   #   ],
   # ],

   [ 'Math::NumSeq::DigitLength',
     [ 1,       # 0
       1,1,1,1,1,1,1,1,1,  # 1 to 9
       2,2,2,2,2,          # 10 onwards
     ],
   ],
   [ 'Math::NumSeq::DigitLength',
     [ 1,              # 0
       1,1,            # 1,2
       2,2,2,2,2,2,    # 10,11,12,20,21,22
       3,3,3,3,3,3,3,3,3,  # 100,101,102,110,111,112,120,121,122
       3,3,3,3,3,3,3,3,3,  # 200,201,202,210,211,212,220,221,222
       4,4,4,4,            # 1000 onwards
     ],
     { radix => 3 },
   ],
   [ 'Math::NumSeq::DigitLength',
     [ 1,       # 0
       1,       # 1
       2,2,     # 2,3
       3,3,3,3, # 4,5,6,7,
       4,4,4,4,4,4,4,4,  # 8-15
       5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5, # 16-31
       6,       # 32
     ],
     { radix => 2 },
   ],
   [ 'Math::NumSeq::DigitLengthCumulative',
     [ 1, 2, 4, 6, 9, 12, 15, 18, 22, 26, 30, 34, 38, 42,
       46, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100,
       105, 110, 115, 120, 125, 130, 136, 142, 148, 154,
       160, 166, 172, 178, 184, 190, 196, 202, 208, 214,
       220, 226, 232, 238, 244, 250, 256, 262, 268, 274,
       280, 286, 292 ],
     { radix => 2 },
   ],

   [ 'Math::NumSeq::Cubes',
     [ 0, 1, 8, 27, 64, 125 ],
     {},
     { value_to_i_floor_below_first => -1 } ],
   # [ 'Math::NumSeq::Cubes', 3,
   #   [ 8, 27, 64, 125 ] ],

   [ 'Math::NumSeq::Even',
     [ 0, 2, 4, 6, 8, 10, 12 ],
     {},
     { value_to_i_floor_below_first => -1 } ],
   # [ 'Math::NumSeq::Even', 5,
   #   [ 6, 8, 10, 12 ] ],

   [ 'Math::NumSeq::All',
     [ 0, 1, 2, 3, 4, 5, 6, 7 ],
     {},
     { value_to_i_floor_below_first => -1 } ],
   [ 'Math::NumSeq::All',
     [ 1,2,3,4,5,6 ],
     { i_start => 1 },
     { value_to_i_floor_below_first => 0 }],

   [ 'Math::NumSeq::Odd',
     [ 1, 3, 5, 7, 9, 11, 13 ],
     {},
     { value_to_i_floor_below_first => -1 } ],
   # [ 'Math::NumSeq::Odd', 6,
   #   [ 7, 9, 11, 13 ] ],

   [ 'Math::NumSeq::SelfLengthCumulative',
     [ 1,2,3,4,5,6,7,8,9,10,
       12,14,16,18,20,22,24,26,
     ],
   ],
   [ 'Math::NumSeq::SelfLengthCumulative',
     [ 1,  # 1
       2,  # 10
       4,  # 100
       7,  # 111
       10, # 1010
       14, # 1110
       18, # 10010
       23, # 10111
       28, # 11100
       33, # 100001
       39, # 100111
       45, # 101101
       51,
     ],
     { radix => 2 },
   ],

   [ 'Math::NumSeq::DeletablePrimes',
     [ 2,3,5,7,
       13,17,23 ],
   ],
   [ 'Math::NumSeq::DeletablePrimes',
     [ 2,3,5,7,0xB,0xD,
       0x13 ],
     { radix => 16 },
   ],

   [ 'Math::NumSeq::ConcatNumbers',
     [ 1, 12, 23, 34, 45, 56, 67, 78, 89, 910, 1011, 1112, 1213 ],
   ],
   [ 'Math::NumSeq::ConcatNumbers',
     [ 12, 123, 234, 345, 456, 567, 678, 789, 8910, 91011, 101112, 111213 ],
     { concat_count => 3 },
   ],
   [ 'Math::NumSeq::ConcatNumbers',
     [ 0x01,  # 0b1
       0x06,  # 0b110
       0x0B,  # 0b1011
       0x1C,  # 0b11100
       0x25,  # 0b100101
       0x2E,  # 0b101110
       0x37,  # 0b110111
       0x78,  # 0b1111000
       0x89,  # 0b10001001
     ],
     { radix => 2 },
   ],
   [ 'Math::NumSeq::ConcatNumbers',
     [ 0x06,  #         0b_0110  0,1,2
       0x1B,  #        0b1_1011  1,2,3
       0x5C,  #      0b101_1100  2,3,4
       0xE5,  #    0b_1110_0101  3,4,5
       0x12E, #   0b1_0010_1110  4,5,6
       0x177, #   0b1_0111_0111  5,6,7
       0x378, #  0b11_0111_1000  6,7,8
     ],
     { radix => 2,
       concat_count => 3,
     },
   ],
   [ 'Math::NumSeq::ConcatNumbers',
     [ 0x1B,   #           0b01_1011  0,1,2,3
       0xDC,   #        0b_1101_1100  1,2,3,4
       0x2E5,  #      0b10_1110_0101  2,3,4,5
       0x72E,  #     0b111_0010_1110  3,4,5,6
       0x977,  #   0b_1001_0111_0111  4,5,6,7
       0x1778, #  0b1_0111_0111_1000  5,6,7,8
       0x3789, # 0b11_0111_1000_1001  6,7,8,9
     ],
     { radix => 2,
       concat_count => 4,
     },
   ],

   [ 'Math::NumSeq::ConcatNumbers',
     [ 1, 12, 23, 34, 45, 56, 67, 78, 89, 910, 1011, 1112, 1213 ],
   ],
   [ 'Math::NumSeq::ConcatNumbers',
     [ 1, 012, 023, 034, 045, 056, 067, 0710, 01011, 01112, 01213 ],
     { radix => 8 },
   ],
   [ 'Math::NumSeq::ConcatNumbers',
     [ 1, 0x12, 0x23, 0x34, 0x45, 0x56, 0x67, 0x78, 0x89,
       0x9A, 0xAB, 0xBC, 0xCD, 0xDE, 0xEF, 0xF10, 0x1011, 0x1112, 0x1213 ],
     { radix => 16 },
   ],

   [ 'Math::NumSeq::HofstadterFigure',
     [ 2, 3, 7, 12, 18, 26, 35, 45, ],
     { start => 2 },
   ],
   [ 'Math::NumSeq::HofstadterFigure',
     [ 1, 3, 7, 12, 18, 26, 35, 45, 56, 69, 83, 98 ],
   ],

   # sqrt(2) = hex 1.6A09E667F3
   [ 'Math::NumSeq::SqrtDigits',
     [ 1, 6, 10, 0, 9, 14, 6, 6, 7, 15, 3 ],
     { radix => 16, sqrt => 2 },
   ],
   [ 'Math::NumSeq::SqrtDigits',
     [ 1, 0, 1, 1, 0, 1, 0, 1, 0, ],
     { radix => 2, sqrt => 2 },
   ],


   [ 'Math::NumSeq::LemoineCount',
     [ 0, 0, 0, 0, 0, 1, 1, 1, 2, 0, 2, 1, 2, 0, 2, 1, 4, 0, ], # per POD
   ],

   [ 'Math::NumSeq::GoldbachCount',
     [ 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 0, 1, 1, 2, 1, 2, 0, ], # per POD
   ],
   [ 'Math::NumSeq::GoldbachCount',
     [ 0, 1, 1, 1, 2, 1, 2, 2, ],
     { on_values => 'even' },
   ],

   [ 'Math::NumSeq::ReReplace',
     [ 1,2,1,2,3,3,1,2,4,4,3,4, ] # from the POD
   ],

   [ 'Math::NumSeq::ReRound',
     [ 1, 2, 4, 6, 10, 12, ]
   ],

   [ 'Math::NumSeq::PrimeFactorCount',
     [ 0,  # 1
       0,  # 2
       1,  # 3    3,5
       0,  # 4
       1,  # 5    5,7
       1,  # 6
       1,  # 7
       0,  # 8
       2,  # 9
       1,  # 10
       1,  # 11    11,13
       1,  # 12
       1,  # 13
       1,  # 14
       2,  # 15
       0,  # 16
       1,  # 17    17,19
       2,  # 18
       1,  # 19
       1,  # 20
       2,  # 21
       1,  # 22
       0,  # 23
     ],
     { prime_type => 'twin',
     },
   ],
   [ 'Math::NumSeq::PrimeFactorCount',
     [ 0,  # 1
       0,  # 2
       1,  # 3    3,5
       0,  # 4
       1,  # 5    5,7
       1,  # 6
       1,  # 7
       0,  # 8
       1,  # 9
       1,  # 10
       1,  # 11
       1,  # 12
       1,  # 13
       1,  # 14
       2,  # 15
       0,  # 16
       1,  # 17    17,19
       1,  # 18    2*3*3
       1,  # 19
       1,  # 20
       2,  # 21
       1,  # 22
       0,  # 23
       1,  # 24
       1,  # 25
     ],
     { multiplicity => 'distinct',
       prime_type => 'twin',
     },
   ],

   [ 'Math::NumSeq::PrimeFactorCount',
     [ 0,  # 1
       1,  # 2    2   2*2+1=5
       1,  # 3    3   2*3+1=7
       2,  # 4
       1,  # 5    5   2*5+1=11
       2,  # 6
       0,  # 7
       3,  # 8
       2,  # 9
       2,  # 10
       1,  # 11    2*11+1=23
       3,  # 12
       0,  # 13
       1,  # 14
       2,  # 15
       4,  # 16
       0,  # 17
       3,  # 18
       0,  # 19
       3,  # 20
       1,  # 21
       2,  # 22
       1,  # 23
     ],
     { prime_type => 'SG',
     },
   ],

   [ 'Math::NumSeq::PrimeFactorCount',
     [ 0,  # 1
       0,  # 2
       0,  # 3
       0,  # 4
       1,  # 5    5   2*2+1=5
       0,  # 6
       1,  # 7    7   2*3+1=7
       0,  # 8
       0,  # 9
       1,  # 10
       1,  # 11    2*5+1=11
       0,  # 12
       0,  # 13
       1,  # 14
       1,  # 15
       0,  # 16
       0,  # 17
       0,  # 18
       0,  # 19
       1,  # 20
       1,  # 21
       1,  # 22
       1,  # 23     2*11+1=23
     ],
     { prime_type => 'safe',
     },
   ],

   [ 'Math::NumSeq::PythagoreanHypots',
     [ 5, 10, 13, 15, 17, 20, ]
   ],
   [ 'Math::NumSeq::PythagoreanHypots',
     [ 5, 13, 17, 25, 29, 37, ],
     { pythagorean_type => 'primitive' },
   ],
   [ 'Math::NumSeq::UlamSequence',
     [ 1, 2, 3, 4, 6, 8, 11, 13, 16, 18, 26, ]
   ],

   [ 'Math::NumSeq::SqrtContinued',
     [ 1, 2,2,2,2,2 ]
   ],

   [ 'Math::NumSeq::AllDigits',
     [ 0,1,2,3,4,5,6,7,8,9,
       1,0, 1,1, 1,2, 1,3, 1,4, 1,5, 1,6 ],
   ],
   [ 'Math::NumSeq::AllDigits',
     [ 0,1,2,3,4,5,6,7,8,9,
       0,1, 1,1, 2,1, 3,1, 4,1, 5,1, 6,1 ],
     { order => 'reverse' },
   ],
   [ 'Math::NumSeq::AllDigits',
     [ 0,1,2,3,4,5,6,7,8,9,
       0,1, 1,1, 1,2, 1,3, 1,4, 1,5, 1,6 ],
     { order => 'sorted' },
   ],

   [ 'Math::NumSeq::RepdigitRadix',
     [  2,  # 0
        0,  # 1
        0,  # 2
        2,  # 3
        3,  # 4
        4,  # 5
        5,  # 6
        2,  # 7
        3,  # 8
     ],
   ],

   [ 'Math::NumSeq::RepdigitAny',
     [  0,
        7,  # 111 base 2
        13, # 111 base 3
        15, # 1111 base 2
        21, # 111 base 4
        26, # 222 base 3
        31, # 11111 base 2
     ],
   ],


   [ 'Math::NumSeq::SqrtEngel',
     [ 1, 3, 5, 5, 16, ],
     { sqrt => 2 } ],
   [ 'Math::NumSeq::SqrtEngel',
     [ 1, 1 ],
     { sqrt => 4 } ],
   [ 'Math::NumSeq::SqrtEngel',
     [ 1, 1, 1 ],
     { sqrt => 9 } ],

   [ 'Math::NumSeq::DigitCountHigh',
     [ 0,  # 0
       0,  # 1
       0,  # 10
       0,  # 11
       0,  # 100
       0,  # 101
     ],
     { radix => 2,
       digit => 0,
     } ],

   [ 'Math::NumSeq::DigitCountHigh',
     [ 0,  # 0
       1,  # 1
       1,  # 10
       2,  # 11
       1,  # 100
       1,  # 101
       2,  # 110
       3,  # 111
       1,  # 1000
       1,  # 1001
       1,  # 1010
       1,  # 1011
       2,  # 1100
       2,  # 1101
       3,  # 111
       4,  # 1111
       1,  # 10000
     ],
     { radix => 2,
       digit => 1,
     } ],

   [ 'Math::NumSeq::DigitCountHigh',
     [ 0,  # 0
       1,  # 1
       0,  # 2
       0,  # 3
       0,  # 4
       1,  # 10
       2,  # 11
       1,  # 12
       1,  # 13
       1,  # 14
       0,  # 20
       0,  # 21
       0,  # 22
       0,  # 23
       0,  # 24
       0,  # 30
       0,  # 31
       0,  # 32
       0,  # 33
       0,  # 34
       0,  # 40
       0,  # 31
       0,  # 31
       0,  # 31
     ],
     { radix => 5,
       digit => 1,
     } ],

   [ 'Math::NumSeq::DigitCountLow',
     [ 0,  # 0
       0,  # 1
       1,  # 10
       0,  # 11
       2,  # 100
       0,  # 101
       1,  # 110
       0,  # 111
       3,  # 1000
     ],
     { radix => 2,
       digit => 0,
     } ],
   [ 'Math::NumSeq::DigitCountLow',
     [ 0,  # 0
       1,  # 1
       0,  # 10
       2,  # 11
       0,  # 100
       1,  # 101
       0,  # 110
       3,  # 111
     ],
     { radix => 2,
       digit => 1,
     } ],
   [ 'Math::NumSeq::DigitCountLow',
     [ 0,  # 0
       0,  # 1
       0,  # 2
       1,  # 10
       0,  # 11
       0,  # 12
       1,  # 20
       0,  # 21
       0,  # 22
       2,  # 100
     ],
     { radix => 3,
       digit => 0,
     } ],
   [ 'Math::NumSeq::DigitCountLow',
     [ 0,  # 0
       0,  # 1
       0,  # 2
       0,  # 3
       0,  # 4
       1,  # 10
       0,  # 11
       0,  # 12
       0,  # 13
       0,  # 14
       1,  # 20
       0,  # 21
       0,  # 22
       0,  # 23
       0,  # 24
       1,  # 30
     ],
     { radix => 5,
       digit => 0,
     } ],


   [ 'Math::NumSeq::AlmostPrimes',
     [ 4, 6, 9, 10, 14, 15, 21, 22, 25, 26, 33, 34, 35, 38,
       39, 46, 49, 51, 55, 57, 58, 62, 65, 69, 74, 77, 82,
       85, 86, 87, 91, 93, 94, 95, 106, 111, 115, 118, 119,
       121, 122, 123, 129, 133, 134, 141, 142, 143, 145,
       146, 155, 158, 159, 161, 166, 169, 177, 178, 183,
       185, 187 ] ],
   #
   # # [ 'Math::NumSeq::SemiPrimesOdd',
   # #   [ 9, 15, 21, 25, 33, 35,
   # #     39, 49, 51, 55, 57, 65, 69, 77,
   # #   ] ],

   [ 'Math::NumSeq::AsciiSelf',
     [ 53,51,53,49,53,51,52,57 ] ],

   [ 'Math::NumSeq::KlarnerRado',
     [ 1,2,4,5,8,9 ] ],

   [ 'Math::NumSeq::BaumSweet',
     [ 1,1,0,1,1,0,0,1,0,1,0,0 ] ],

   [ 'Math::NumSeq::Polygonal',  # pentagonal
     [ 0, 1,   5, 12,   22 ],  { polygonal => 5 },
   ],
   [ 'Math::NumSeq::Polygonal',  # pentagonal second
     [ 0, 2,   7, 15,   26 ],  { polygonal => 5, pairs => 'second' },
   ],
   [ 'Math::NumSeq::Polygonal',  # pentagonal average
     [ 0, 1.5, 6, 13.5, 24 ],  { polygonal => 5, pairs => 'average' },
   ],
   [ 'Math::NumSeq::Polygonal',  # pentagonal both
     [ 0, 1,2, 5,7, 12,15, 22,26 ],
     { polygonal => 5, pairs => 'both' },
   ],

   [ 'Math::NumSeq::CollatzSteps',  # both
     [ 0,   # 1
       1,   # 2 -> 1
       7,   # 3 -> 10->5 -> 16->8->4->2->1
       2,   # 4 -> 2 -> 1
       5,   # 5 -> 16->8->4->2->1
       8,   # 6 -> 3->... (7of)
     ],
   ],
   [ 'Math::NumSeq::CollatzSteps',  # up
     [ 0,   # 1
       0,   # 2 -> 1
       2,   # 3 -> 10->5 -> 16->8->4->2->1
       0,   # 4 -> 2 -> 1
       1,   # 5 -> 16->8->4->2->1
       2,   # 6 -> 3->... (2up)
     ],
     { step_type => 'up' },
   ],
   [ 'Math::NumSeq::CollatzSteps',  # down
     [ 0,   # 1
       1,   # 2 -> 1
       5,   # 3 -> 10->5 -> 16->8->4->2->1
       2,   # 4 -> 2 -> 1
       4,   # 5 -> 16->8->4->2->1
       6,   # 6 -> 3->... (5down)
     ],
     { step_type => 'down' },
   ],

   [ 'Math::NumSeq::NumAronson',
     [ 1, 4,
       6,7,8, 9,11,13,
       15,16,17,18,19,20, 21,23,25,27,29,31,
       33,34,35,36,37,38,39,40,41,42,43,44,
       45,47,49,51,53,55,57,59,61,63,65,67,69,
     ],
     undef,
   ],

   [ 'Math::NumSeq::Tribonacci',
     [ 0, 0, 1, 1, 2, 4, 7, 13, 24, ],
   ],

   [ 'Math::NumSeq::DigitSum',
     [ 0,1,1,2,
       1,2,2,3,
       1,2,2,3,
       2,3,3,4 ],
     { radix => 2 },
   ],
   [ 'Math::NumSeq::DigitSum',
     [ 0,1,2,3,4,5,6,7,8,9,
       1,2,3,4,5,6,7,8,9,10,
       2,3,4,5,6,7,8,9,10,11,
     ],
   ],
   [ 'Math::NumSeq::DigitSum',
     [ 0,1,4,9,16,25,36,49,64,81,    # 0 to 9
       1,2,5,10,17,26,37,50,65,82,   # 10 to 19
       4,5,8,13,20,29,40,53,68,85,   # 20 to 29
     ],
     { power => 2 },
   ],

   [ 'Math::NumSeq::DigitProduct',
     [ 0,
       1,
       0,  # 10
       1,  # 11,
       0,
       0,
       0,
       1,  # 111
       0, ],
     { radix => 2 } ],

   [ 'Math::NumSeq::DigitProduct',
     [ 0,1,2,
       0,1,2,
       0,2,4,  # 20,21,22

       0,0,0,  # 100,101,102
       0,1,2,
       0,2,4,

       0,0,0,
       0,2,4,
       0,4,8, ],
     { radix => 3 } ],

   [ 'Math::NumSeq::FractionDigits',
     [ 0,9,0,9,0,9,0,9,0,9,0,9, ],
     { fraction => '1/11' } ],

   [ 'Math::NumSeq::TotientCumulative',
     [ 0, 1, 2, 4, 6, 10, 12, 18, 22, 28, 32, 42 ],
   ],

   # [ 'Math::NumSeq::Loeschian',
   #   [ 0,1,3,4,7,9,12,13,16,19,21,25 ] ],

   [ 'Math::NumSeq::DigitCount',
     [ 0,1,1,2,
       1,2,2,3,
       1,2,2,3,
       2,3,3,4 ],
     { radix => 2,
     } ],
   [ 'Math::NumSeq::DigitCount',
     [ 0,  # 0
       0,  # 1
       1,  # 10
       0,  # 11
       2,  # 100
       1,  # 101
       1,  # 110
       0,  # 111
       3,  # 1000
       2,  # 1001
     ],
     { radix => 2,
       digit => 0,
     } ],
   [ 'Math::NumSeq::DigitCount',
     [ 0,0,0,0,0,
       0,0,0,0,1,
       0,0,0,0,0,
       0,0,0,0,1,
     ],
     { radix => 10,
       digit => 9,
     } ],

   [ 'Math::NumSeq::CullenNumbers',
     [ 1, 3, 9, 25, 65, 161, 385, 897, 2049, 4609, ] ],

   # [ 'Math::NumSeq::SumXsq3Ysq',
   #   [ 4,7,12,13,16,19,21,28,31,36,37 ] ],

   [ 'Math::NumSeq::Palindromes',
     [ 0, 1, 3, 5, 7, 9, 15, 17, 21, 27, 31, 33, 45, 51,
       63, 65, 73, 85, 93, 99, 107, 119, 127, 129, 153,
       165, 189, 195, 219, 231, 255, 257, 273, 297, 313,
       325, 341, 365, 381, 387, 403, 427, 443, 455, 471,
       495, 511, 513, 561, 585, 633, 645, 693, 717, 765,
       771, 819, 843, ],
     { radix => 2 },
   ],
   [ 'Math::NumSeq::Palindromes',
     [ 0, 1, 2, 4, 8, 10, 13, 16, 20, 23, 26, 28, 40, 52,
       56, 68, 80, 82, 91, 100, 112, 121, 130, 142, 151,
       160, 164, 173, 182, 194, 203, 212, 224, 233, 242,
       244, 280, 316, 328, 364, 400, 412, 448, 484, 488,
       524, 560, 572, 608, 644, 656, 692, 728, 730, 757,
       784, 820, 847, 874, 910, ],
     { radix => 3 },
   ],
   [ 'Math::NumSeq::Palindromes',
     [ 0, 1, 2, 3, 5, 10, 15, 17, 21, 25, 29, 34, 38, 42,
       46, 51, 55, 59, 63, 65, 85, 105, 125, 130, 150, 170,
       190, 195, 215, 235, 255, 257, 273, 289, 305, 325, 341,
       357, 373, 393, 409, 425, 441, 461, 477, 493, 509, 514,
       530, 546, 562, 582, 598, 614, 630, 650, 666, 682, 698,
       718, 734, ],
     { radix => 4 },
   ],
   [ 'Math::NumSeq::Palindromes',
     [ 0, 1, 2, 3, 4, 6, 12, 18, 24, 26, 31, 36, 41, 46,
       52, 57, 62, 67, 72, 78, 83, 88, 93, 98, 104, 109, 114,
       119, 124, 126, 156, 186, 216, 246, 252, 282, 312, 342,
       372, 378, 408, 438, 468, 498, 504, 534, 564, 594, 624,
       626, 651, 676, 701, 726, 756, 781, ],
     { radix => 5 },
   ],
   [ 'Math::NumSeq::Palindromes',
     [ 0, 1, 2, 3, 4, 5, 7, 14, 21, 28, 35, 37, 43, 49, 55,
       61, 67, 74, 80, 86, 92, 98, 104, 111, 117, 123, 129,
       135, 141, 148, 154, 160, 166, 172, 178, 185, 191, 197,
       203, 209, 215, 217, 259, 301, 343, 385, 427, 434, 476,
       518, 560, 602, 644, 651, 693, 735, ],
     { radix => 6 },
   ],
   [ 'Math::NumSeq::Palindromes',
     [ 0, 1, 2, 3, 4, 5, 6, 8, 16, 24, 32, 40, 48, 50, 57,
       64, 71, 78, 85, 92, 100, 107, 114, 121, 128, 135, 142,
       150, 157, 164, 171, 178, 185, 192, 200, 207, 214, 221,
       228, 235, 242, 250, 257, 264, 271, 278, 285, 292, 300,
       307, 314, 321, 328, 335, 342, ],
     { radix => 7 },
   ],
   [ 'Math::NumSeq::Palindromes',
     [ 0, 1, 2, 3, 4, 5, 6, 7, 9, 18, 27, 36, 45, 54, 63,
       65, 73, 81, 89, 97, 105, 113, 121, 130, 138, 146, 154,
       162, 170, 178, 186, 195, 203, 211, 219, 227, 235, 243,
       251, 260, 268, 276, 284, 292, 300, 308, 316, 325, 333,
       341, 349, 357, 365, 373, 381, 390, ],
     { radix => 8 },
   ],
   [ 'Math::NumSeq::Palindromes',
     [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 20, 30, 40, 50, 60,
       70, 80, 82, 91, 100, 109, 118, 127, 136, 145, 154,
       164, 173, 182, 191, 200, 209, 218, 227, 236, 246, 255,
       264, 273, 282, 291, 300, 309, 318, 328, 337, 346, 355,
       364, 373, 382, 391, 400, 410, 419, ],
     { radix => 9 },
   ],
   [ 'Math::NumSeq::Palindromes',
     [ 0,1,2,3,4,5,6,7,8,9,
       11,22,33,44,55,66,77,88,99,
       101,111,121,131,141,151,161,171,181,191,
       202,212,222,232,242,252,262,272,282,292,
       303,313,323,333,343,353,363,373,383,393,
       404,414,424,434,444,454,464,474,484,494,
       505,515,525,535,545,555,565,575,585,595,
       606,616,626,636,646,656,666,676,686,696,
       707,717,727,737,747,757,767,777,787,797,
       808,818,828,838,848,858,868,878,888,898,
       909,919,929,939,949,959,969,979,989,999,
       1001,1111,1221,1331,1441,1551,1661,1771,1881,1991,
     ] ],

   [ 'Math::NumSeq::Factorials',
     [ 1, 1, 2, 6, 24, 120, 720 ],
   ],

   [ 'Math::NumSeq::Primorials',
     [ 1, 2, 6, 30, 210, ],
   ],

   # [ 'Math::NumSeq::SumTwoSquares',
   #   [ 2, 5, 8, 10, 13, 17, 18, 20, 25, 26, 29, 32, 34, 37,
   #     40, 41, 45, 50, 52, 53, 58, 61, 65, 68, 72, 73, 74,
   #     80, 82, 85, 89, 90, 97, 98, 100, 101, 104, 106, 109,
   #     113, 116, 117, 122, 125, 128, 130, 136, 137, 145,
   #     146, 148, 149, 153, 157, 160, 162, 164, 169, 170,
   #     173, 178 ] ],
   #
   # [ 'Math::NumSeq::PythagoreanHypots',
   #   [ 5, 10, 13, 15, 17, 20, 25, 26, 29, 30 ] ],

   [ 'Math::NumSeq::PolignacObstinate',
     [ 1, 127, ] ],

   [ 'Math::NumSeq::RadixWithoutDigit',
     [ 1, 2,    # 1,2
       4,5,     # 11,12
     ],
     { radix => 3,
       digit => 0,
     },
   ],
   [ 'Math::NumSeq::RadixWithoutDigit',
     [ 0, 2,    # 0,2
       6, 8,    # 20, 22
     ],
     { radix => 3,
       digit => 1,
     },
   ],
   [ 'Math::NumSeq::RadixWithoutDigit',
     [ 0, 1,    # 0,1
       3, 4,    # 10, 11
       # 6, 7,    # 20, 21
       9, 10,   # 100, 101
       12, 13,  # 110, 111
       27, 28,  # 1000, 1001
     ],
     { radix => 3,
       digit => 2,
     },
   ],
   [ 'Math::NumSeq::RadixWithoutDigit',
     [ 0, 1,    # 0,1
       3, 4,    # 10, 11
       # 6, 7,    # 20, 21
       9, 10,   # 100, 101
       12, 13,  # 110, 111
       27, 28,  # 1000, 1001
     ],
     { radix => 3,
       digit => -1,
     },
   ],

   [ 'Math::NumSeq::RadixWithoutDigit',
     [ 0x01, 0x02, 0x03,    # 1,2,3
       0x05, 0x06, 0x07,    # 11,12,13
       0x09, 0x0A, 0x0B,    # 21,22,23
       0x0D, 0x0E, 0x0F,    # 31,32,33
       0x15, 0x16, 0x17,    # 111,112,113
     ],
     { radix => 4,
       digit => 0,
     },
   ],
   [ 'Math::NumSeq::RadixWithoutDigit',
     [ 0x00, 0x02, 0x03,    # 0,2,3
       0x08, 0x0A, 0x0B,    # 20,22,23
     ],
     { radix => 4,
       digit => 1,
     },
   ],
   [ 'Math::NumSeq::RadixWithoutDigit',
     [ 0x00, 0x01, 0x03,    # 0,1,3
       0x04, 0x05, 0x07,    # 10,11,13
     ],
     { radix => 4,
       digit => 2,
     },
   ],
   [ 'Math::NumSeq::RadixWithoutDigit',
     [ 0x00, 0x01, 0x02,    # 0,1,2
       0x04, 0x05, 0x06,    # 10,11,12
       0x08, 0x09, 0x0A,    # 20,21,22
       0x10, 0x11, 0x12,    # 100,101,102
       0x14, 0x15, 0x16,    # 200,201,202
     ],
     { radix => 4,
       digit => 3,
     },
   ],

   [ 'Math::NumSeq::StarNumbers',
     [ 1, 13, 37, 73, 121, ],
     {},
     { value_to_i_floor_below_first => 0 },
   ],

   [ 'Math::NumSeq::Polygonal', # triangular
     [ 0, 1, 3, 6, 10, 15, 21 ],
     { polygonal => 3 },
   ],
   [ 'Math::NumSeq::Polygonal', # squares
     [ 0, 1, 4, 9, 16 ],
     { polygonal => 4 },
   ],
   [ 'Math::NumSeq::Polygonal',  # hexagonal
     [ 0, 1, 6, 15, 28, 45, 66 ],
     { polygonal => 6 },
   ],
   [ 'Math::NumSeq::Polygonal',    # heptagonal
     [ 0, 1, 7, 18, 34, 55, 81, ],
     { polygonal => 7 },
   ],
   [ 'Math::NumSeq::Polygonal',   # octagonal
     [ 0, 1, 8, 21, 40, 65, 96, ],
     { polygonal => 8 },
   ],
   [ 'Math::NumSeq::Polygonal',                  # nonagonal
     [ 0, 1, 9, 24, 46, 75, 111, 154, 204, 261, 325, 396,
       474, 559, 651, 750, 856, 969, ],
     { polygonal => 9 },
   ],
   [ 'Math::NumSeq::Polygonal',
     [ 0, 1, 10, 27, 52, 85, 126, 175 ],    # decagonal
     { polygonal => 10 },
   ],
   [ 'Math::NumSeq::Polygonal',
     [ 0, 1, 11, 30, 58, 95, 141, 196, 260 ],  # hendecagonal
     { polygonal => 11 },
   ],
   [ 'Math::NumSeq::Polygonal',  # 12-gonal
     [ 0, 1, 12, 33, 64, 105, 156, 217, 288, 369, 460, 561,
       672, 793, 924, 1065, 1216, 1377, 1548, 1729, 1920,
       2121, 2332, 2553, 2784, 3025, 3276, 3537, 3808,
       4089, 4380, 4681, 4992, 5313, 5644, 5985, 6336,
       6697, 7068, 7449, 7840, 8241, 8652 ],
     { polygonal => 12 },
   ],
   [ 'Math::NumSeq::Polygonal',  # 13-gonal
     [ 0, 1, 13, 36, 70, 115, 171, 238, 316, 405, 505, 616,
       738, 871, 1015, ],
     { polygonal => 13 },
   ],
   [ 'Math::NumSeq::Polygonal',  # 14-gonal
     [ 0, 1, 14, 39, 76, 125, 186, ],
     { polygonal => 14 },
   ],


   [ 'Math::NumSeq::Tetrahedral',
     [ 0, 1, 4, 10, 20, 35, 56, 84, 120 ],
     {},
     { value_to_i_floor_below_first => -3 } ],

   [ 'Math::NumSeq::Emirps',
     [ 13, 17, 31, 37, 71, 73, 79, 97, 107, 113, 149, 157,
       167, 179, 199, 311, 337, 347, 359, 389, 701, 709,
       733, 739, 743, 751, 761, 769, 907, 937, 941, 953,
       967, 971, 983, 991, 1009, 1021, 1031, 1033, 1061,
       1069, 1091, 1097, 1103, 1109, 1151, 1153, 1181, 1193
     ] ],

   [ 'Math::NumSeq::Squares',
     [ 0, 1, 4, 9, 16, 25 ] ],
   # [ 'Math::NumSeq::Squares', 3,
   #   [ 4, 9, 16, 25 ] ],

   [ 'Math::NumSeq::Perrin',
     [ 3, 0, 2, 3, 2, 5, 5, 7, 10, 12, 17 ] ],
   # [ 'Math::NumSeq::Padovan',
   #   [ 1, 1, 1, 2, 2, 3, 4, 5, 7, 9, 12 ],
   #   undef,
   #   { bfile_offset => 5 } ],

   [ 'Math::NumSeq::Primes',
     [ 2, 3, 5, 7, 11, 13, 17 ] ],
   # [ 'Math::NumSeq::Primes', 10,
   #   [ 11, 13, 17 ] ],

   [ 'Math::NumSeq::TwinPrimes',
     [ 3, 5, 7, 11, 13, 17, 19, 29, 31 ],
     { pairs => 'both' },
   ],
   # [ 'Math::NumSeq::TwinPrimes', 10,     # from given values_min ...
   #   [ 11, 13, 17, 19, 29, 31 ],
   #   { pairs => 'both' },
   # ],

   [ 'Math::NumSeq::TwinPrimes',
     [ 3, 5, 11, 17, 29 ],
     { pairs => 'first' },
   ],
   # [ 'Math::NumSeq::TwinPrimes', 4,    # from given values_min ...
   #   [ 5, 11, 17, 29 ],
   #   { pairs => 'first' },
   # ],

   [ 'Math::NumSeq::TwinPrimes',
     [ 5, 7, 13, 19, 31 ],
     { pairs => 'second' },
   ],
   # [ 'Math::NumSeq::TwinPrimes', 6,    # from given values_min ...
   #   [ 7, 13, 19, 31 ],
   #   { pairs => 'second' },
   # ],

   # [ 'Math::NumSeq::ThueMorseEvil',
   #   [ 0, 3, 5, 6, 9, 10, 12, 15, 17, 18, 20, 23, 24, 27,
   #     29, 30, 33, 34, 36, 39, 40, 43, 45, 46, 48, 51, 53,
   #     54, 57, 58, 60, 63, 65, 66, 68, 71, 72, 75, 77, 78,
   #     80, 83, 85, 86, 89, 90, 92, 95, 96, 99, 101, 102,
   #     105, 106, 108, 111, 113, 114, 116, 119, 120, 123,
   #     125, 126, 129 ] ],
   # [ 'Math::NumSeq::ThueMorseEvil', [ 3, 5, 6, 9 ] ],
   # [ 'Math::NumSeq::ThueMorseEvil', 2, [ 3, 5, 6, 9 ] ],
   # [ 'Math::NumSeq::ThueMorseEvil', 3, [ 3, 5, 6, 9 ] ],
   # [ 'Math::NumSeq::ThueMorseEvil', 4, [ 5, 6, 9 ] ],
   # [ 'Math::NumSeq::ThueMorseEvil', 5, [ 5, 6, 9 ] ],
   #
   # [ 'Math::NumSeq::ThueMorseOdious',
   #   [ 1, 2, 4, 7, 8, 11, 13, 14, 16, 19, 21, 22, 25, 26,
   #     28, 31, 32, 35, 37, 38, 41, 42, 44, 47, 49, 50, 52,
   #     55, 56, 59, 61, 62, 64, 67, 69, 70, 73, 74, 76, 79,
   #     81, 82, 84, 87, 88, 91, 93, 94, 97, 98, 100, 103,
   #     104, 107, 109, 110, 112, 115, 117, 118, 121, 122,
   #     124, 127, 128 ] ],
   # [ 'Math::NumSeq::ThueMorseOdious', [ 1, 2, 4, 7, ] ],
   # [ 'Math::NumSeq::ThueMorseOdious', 2, [ 2, 4, 7, ] ],
   # [ 'Math::NumSeq::ThueMorseOdious', 3, [ 4, 7, ] ],
   # [ 'Math::NumSeq::ThueMorseOdious', 4, [ 4, 7, ] ],
   # [ 'Math::NumSeq::ThueMorseOdious', 5, [ 7, ] ],

   [ 'Math::NumSeq::Beastly',
     [ 666,
       1666, 2666, 3666, 4666, 5666,
       6660,6661,6662,6663,6664,6665,6666,6667,6668,6669,
       7666, 8666, 9666,
       10666,11666,12666,13666,14666,15666,
       16660,16661,16662,16663,16664,16665,16666,16667,16668,
       16669,
       17666,18666,19666,
       20666,21666,22666,23666,24666,25666,
       26660,26661,26662,26663,26664,26665,26666,26667,26668,
       26669,
       27666,28666,29666,
     ] ],
   [ 'Math::NumSeq::Beastly',
     [ 0666,
       01666, 02666, 03666, 04666, 05666,
       06660,06661,06662,06663,06664,06665,06666,06667,
       07666,
       010666,011666,012666,013666,014666,015666,
       016660,016661,016662,016663,016664,016665,016666,016667,
       017666,
       020666,021666,022666,023666,024666,025666,
       026660,026661,026662,026663,026664,026665,026666,026667,
       027666,
     ],
     { radix => 8 } ],

   # [ 'Math::NumSeq::PrimeQuadraticEuler',
   #   [ 41, 43, 47, 53, 61, 71, 83, 97, 113, 131, 151 ] ],
   # [ 'Math::NumSeq::PrimeQuadraticLegendre',
   #   [ 29, 31, 37, 47, 61, 79, 101, 127, 157, 191, 229 ] ],
   # [ 'Math::NumSeq::PrimeQuadraticHonaker',
   #   [ 59, 67, 83, 107, 139, 179, 227, 283, 347, 419, 499 ] ],

   # # [ 'Math::NumSeq::GolayRudinShapiro',
   # #   [ 0,1,2,4,5,7 ] ],
   # # http://oeis.org/A022155
   # # positions of -1, odd num of "11"s
   # [ 'Math::NumSeq::GolayRudinShapiro', 3,
   #   [ 3, 6, 11, 12, 13, 15, 19, 22, 24, 25,
   #     26, 30, 35, 38, 43, 44, 45, 47, 48, 49,
   #     50, 52, 53, 55, 59, 60, 61, 63, 67, 70,
   #     75, 76, 77, 79, 83, 86, 88, 89, 90, 94,
   #     96, 97, 98, 100, 101, 103, 104, 105,
   #     106, 110, 115, 118, 120, 121, 122, 126,
   #     131, 134, 139, 140 ] ],

  ) {
  my ($class, $want, $values_options, $test_options) = @$elem;
  $values_options ||= {};
  my $good = 1;
  my $lo = $want->[0];

  ref $want eq 'ARRAY' or die "$class, oops, want array is not an array";

  my $name = join (' ',
                   $class,
                   map {"$_=$values_options->{$_}"} keys %$values_options);

  ### $class
  eval "require $class; 1" or die $@;
  my $seq = $class->new (%$values_options);

  $seq->oeis_anum;
  $seq->description;
  $class->description;
  my $i_start = $seq->i_start;

  #### $want
  my $hi = $want->[-1];
  # MyTestHelpers::diag ("$name $lo to ",$hi);

  # SKIP: {
  #    require Module::Load;
  #    if (! eval { Module::Load::load ($class);
  #                 $seq = $class->new (lo => $lo,
  #                                     hi => $hi,
  #                                     %$values_options);
  #                 1; }) {
  #      my $err = $@;
  #      diag "$name caught error -- $err";
  #      if (my $module = $test_options->{'module'}) {
  #        if (! eval "require $module; 1") {
  #          skip "$name due to no module $module", 2;
  #        }
  #        diag "But $module loads successfully";
  #      }
  #      die $err;
  #    }

  # next() values, incl after rewind()
  foreach my $rewind (0, 1) {
    {
      my $i = $seq->tell_i;
      ok ($i, $i_start, "$name tell_i() == i_start(), rewind=$rewind");
    }

    my $got = [ map { my ($i, $value) = $seq->next; $value } 0 .. $#$want ];
    foreach (@$got) { if (defined $_ && $_ == 0) { $_ = 0 } }  # avoid "-0"
    foreach (@$got) { if (! defined $_) { $_ = 'undef' } }
    foreach (@$got) { if (ref $_) { $_ = "$_" }
                      elsif ($_ > ~0) { $_ = sprintf "%.0f", $_ } }
    ### ref: ref $got->[-1]

    my $got_str = join(',', @$got);
    my $want_str = join(',', @$want);

    # stray leading "+" from perl 5.6.2 on ConcatNumbers NVs or something
    $got_str =~ s/^\+//;
    $got_str =~ s/,\+/,/g;

    ok ($got_str, $want_str, "$name by next(), lo=$lo hi=$hi");
    if ($got_str ne $want_str) {
      MyTestHelpers::diag ("got len ".scalar(@$got));
      MyTestHelpers::diag ("want len ".scalar(@$want));
      MyTestHelpers::diag ("got  ", substr ($got_str, 0, 256));
      MyTestHelpers::diag ("want ", substr ($want_str, 0, 256));
    }

    ### rewind() ...
    $seq->rewind;
  }

  ### ith() values ...
  {
    my $skip;
    my $got_str;
    if (! $seq->can('ith')) {
      $skip = "$name no ith()";
    } else {
      my $got = [ map { my $i = $_ + $i_start;
                        $seq->ith($i) } 0 .. $#$want ];
      ### $got
      foreach (@$got) { if (defined $_ && $_ == 0) { $_ = 0 } }  # avoid "-0"
      foreach (@$got) { if (! defined $_) { $_ = 'undef' } }
      foreach (@$got) { if (ref $_) { $_ = "$_" }
                        elsif ($_ > ~0) { $_ = sprintf "%.0f", $_ } }
      ### ref: ref $got->[-1]

      $got_str = join(',', @$got);
      # stray leading "+" from perl 5.6.2 on ConcatNumbers NVs or something
      $got_str =~ s/^\+//;
      $got_str =~ s/,\+/,/g;
    }
    my $want_str = join(',', @$want);
    skip ($skip, $got_str, $want_str, "$name by ith(), lo=$lo hi=$hi");
  }

  ### ith_pair() values ...
  {
    my $skip;
    my $got_str;
    if (! $seq->can('ith_pair')) {
      $skip = "$name no ith_pair()";
    } else {
      my $got = [ map { my $i = $_ + $i_start;
                        $seq->ith_pair($i) } 0 .. $#$want-1 ];
      ### $got
      foreach (@$got) { if (defined $_ && $_ == 0) { $_ = 0 } }  # avoid "-0"
      foreach (@$got) { if (! defined $_) { $_ = 'undef' } }
      foreach (@$got) { if (ref $_) { $_ = "$_" }
                        elsif ($_ > ~0) { $_ = sprintf "%.0f", $_ } }
      ### ref: ref $got->[-1]

      $got_str = join(',', @$got);
      # stray leading "+" from perl 5.6.2 on ConcatNumbers NVs or something
      $got_str =~ s/^\+//;
      $got_str =~ s/,\+/,/g;
    }
    my $want_pairs = [ map { ($want->[$_],$want->[$_+1]) } 0 .. $#$want-1 ];
    my $want_str = join(',', @$want_pairs);
    skip ($skip, $got_str, $want_str, "$name by ith_pair(), lo=$lo hi=$hi");
  }

  ### value_to_i() etc ...
  {
    ### $want
    my $skip;
    my $bad = 0;

    foreach my $p (0 .. $#$want) {
      my $i = $p + $i_start;
      my $value = $want->[$p];

      foreach my $using_bigint (0, 1) {
        my $value = ($using_bigint && $value == int($value)
                     ? Math::BigInt->new($value)
                     : $value);
        my $want_i = $i;
        my $want_p = $p;
        # skip back over repeat values
        while ($want_p > 0 && $want->[$want_p-1] == $value) {
          $want_i--;
          $want_p--;
        }
        if ($seq->can('value_to_i')) {
          my $got_i = $seq->value_to_i($value);
          if (! equal($got_i, $want_i)) {
            MyTestHelpers::diag ("$name value_to_i($value) want ",$want_i," got ",$got_i);
            $bad++
          }
        }
        if ($seq->can('value_to_i_floor')) {
          my $got_i = $seq->value_to_i_floor($value);
          if (! equal($got_i, $want_i)) {
            MyTestHelpers::diag ("$name value_to_i_floor($value) want ",$want_i," got ",$got_i);
            $bad++
          }
        }
        if ($seq->can('value_to_i_ceil')) {
          my $got_i = $seq->value_to_i_ceil($value);
          if (! equal($got_i, $want_i)) {
            MyTestHelpers::diag ("$name value_to_i_ceil($value) want $want_i got $got_i");
            $bad++
          }
        }
      }

      if ($p < $#$want && $value+1 < $want->[$p+1]) {
        {
          my $try_value = $value+0.25;

          if ($seq->can('value_to_i')) {
            my $got_i = $seq->value_to_i($try_value);
            if (defined $got_i) {
              MyTestHelpers::diag ("$name value_to_i($value+0.25=$try_value) want undef got ",$got_i);
              $bad++
            }
          }
          if ($seq->can('value_to_i_floor')) {
            my $got_i = $seq->value_to_i_floor($try_value);
            if ($got_i != $i) {
              MyTestHelpers::diag ("$name value_to_i_floor($value+0.25=$try_value) want $i got $got_i");
              $bad++
            }
          }
          if ($seq->can('value_to_i_ceil')) {
            my $got_i = $seq->value_to_i_ceil($try_value);
            my $want_i = $i+1;
            if ($got_i != $want_i) {
              MyTestHelpers::diag ("$name value_to_i_ceil($value+0.25=$try_value) want $want_i got $got_i");
              $bad++
            }
          }
        }
        {
          my $try_value = $value+1;

          if ($seq->can('value_to_i')) {
            my $got_i = $seq->value_to_i($try_value);
            if (defined $got_i) {
              MyTestHelpers::diag ("$name value_to_i($value+1=$try_value) want undef got ",$got_i);
              $bad++
            }
          }
          if ($seq->can('value_to_i_floor')) {
            my $got_i = $seq->value_to_i_floor($try_value);
            if ($got_i != $i) {
              MyTestHelpers::diag ("$name value_to_i_floor($value+1=$try_value) want $i got $got_i");
              $bad++
            }
          }
          if ($seq->can('value_to_i_ceil')) {
            my $got_i = $seq->value_to_i_ceil($try_value);
            my $want_i = $i+1;
            if ($got_i != $want_i) {
              MyTestHelpers::diag ("$name value_to_i_ceil($value+1=$try_value) want $want_i got $got_i");
              $bad++
            }
          }
        }
      }

      if ($p == 0 || $value-1 > $want->[$p-1]) {
        {
          my $try_value = $value-0.25;
          my $want_i = $i-1;
          if ($want_i < $seq->i_start) {
            if (defined $test_options->{'value_to_i_floor_below_first'}) {
              $want_i = $test_options->{'value_to_i_floor_below_first'};
            } else {
              $want_i = $seq->i_start;
            }
          }
          if ($seq->can('value_to_i')) {
            my $got_i = $seq->value_to_i($try_value);
            if (defined $got_i) {
              MyTestHelpers::diag ("$name value_to_i($value-0.25=$try_value) want undef got $got_i");
              $bad++
            }
          }
          if ($seq->can('value_to_i_floor')) {
            my $got_i = $seq->value_to_i_floor($try_value);
            if ($got_i != $want_i) {
              MyTestHelpers::diag ("$name value_to_i_floor($value-0.25=$try_value) want $want_i got $got_i");
              $bad++
            }
          }
          if ($seq->can('value_to_i_ceil')) {
            my $got_i = $seq->value_to_i_ceil($value);
            if (! defined $got_i || $got_i != $i) {
              MyTestHelpers::diag ("$name value_to_i_ceil($value-0.25=$try_value) want $i got $got_i");
              $bad++
            }
          }
        }
        {
          my $try_value = $value-1;
          my $want_i = $i-1;
          if ($want_i < $seq->i_start) {
            if (defined $test_options->{'value_to_i_floor_below_first'}) {
              $want_i = $test_options->{'value_to_i_floor_below_first'};
            } else {
              $want_i = $seq->i_start;
            }
          }
          if ($seq->can('value_to_i_floor')) {
            my $got_i = $seq->value_to_i_floor($try_value);
            if ($got_i != $want_i) {
              MyTestHelpers::diag ("$name value_to_i_floor($value-1=$try_value) want $want_i got $got_i");
              $bad++
            }
          }
          if ($seq->can('value_to_i_ceil')) {
            my $got_i = $seq->value_to_i_ceil($value);
            if (! defined $got_i || $got_i != $i) {
              MyTestHelpers::diag ("$name value_to_i_ceil($value) want $i got $got_i");
              $bad++
            }
          }
        }
      }
    }
    my $want_str = join(',', @$want);
    skip ($skip, $bad, 0, "$name value_to_i_floor()");
  }

  ### seek_to_i() ...
  {
    my $skip;
    my $bad = 0;
    if (! $seq->can('seek_to_i')) {
      $skip = "$name no seek_to_i()";
    } else {
      foreach my $p (reverse 0 .. $#$want) {
        my $got_str = '';
        my $want_str = '';
        my $i = $i_start + $p;
        $seq->seek_to_i($i);

        my $want_i = $i;
        foreach my $pp ($p .. _min($p+20,$#$want)) {
          my ($got_i, $value) = $seq->next;
          if ($want_i != $got_i) {
            die "oops $name seek_to_i() got_i=$got_i want i=$i";
          }
          if (defined $value && $value == 0) { $value = 0; }  # avoid "-0"
          if (! defined $value) { $value = 'undef' }
          if (ref $value) { $value = "$value" }
          elsif ($value > ~0) { $value = sprintf "%.0f", $value }
          $got_str  .= sprintf ',%b', $value;
          $want_str .= sprintf ',%b', $want->[$pp];
          # $got_str  .= ",$value";
          # $want_str .= ",$want->[$pp]";
          $want_i++;
        }
        # stray leading "+" from perl 5.6.2 on ConcatNumbers NVs or something
        $got_str =~ s/^\+//;
        $got_str =~ s/,\+/,/g;

        if ($got_str ne $want_str) {
          MyTestHelpers::diag ("$name seek_to_i($i)\nwant $want_str\ngot  $got_str");
          if (++$bad > 8) {
            die;
            last;
          }
        }
      }
    }
    skip ($skip, $bad, 0,
          "$name by seek_to_i() next(), lo=$lo hi=$hi");
  }

  ### seek_to_value() ...
  {
    my $skip;
    my $got_str;
    if (! $seq->can('seek_to_value')) {
      $skip = "$name no seek_to_value()";
    } else {
      my @got;
      foreach my $p (reverse 0 .. $#$want) {
        my $i = $i_start + $p;
        $seq->seek_to_value($want->[$p]);
        my ($got_i, $value) = $seq->next;
        if ($i != $got_i) {
          die "oops $name seek_to_value() got_i=$got_i want i=$i";
        }
        $got[$p] = $value;
      }
      foreach (@got) { if (defined $_ && $_ == 0) { $_ = 0 } }  # avoid "-0"
      foreach (@got) { if (! defined $_) { $_ = 'undef' } }
      foreach (@got) { if (ref $_) { $_ = "$_" }
                        elsif ($_ > ~0) { $_ = sprintf "%.0f", $_ } }
      ### ref: ref $got[-1]

      $got_str = join(',', @got);
      # stray leading "+" from perl 5.6.2 on ConcatNumbers NVs or something
      $got_str =~ s/^\+//;
      $got_str =~ s/,\+/,/g;
    }
    my $want_str = join(',', @$want);
    skip ($skip, $got_str, $want_str,
          "$name by seek_to_value() next(), lo=$lo hi=$hi");
  }

  # value_to_i_estimate() should be an integer, and should be clean to
  # negatives and zero
  {
    my $skip;
    my $bad = 0;
    if (! $seq->can('value_to_i_estimate')) {
      $skip = "$name no value_to_i_estimate()";
    } else {
      foreach my $value (Math::BigInt->new(12345),
                         -100, -1, 0, @$want,
                        ) {
        my $try_value = $value - 1;
        my $got_i = $seq->value_to_i_estimate($try_value);
        if ($got_i != int($got_i)) {
          MyTestHelpers::diag ("$name value_to_i_estimate($try_value) not an integer: $got_i");
          $bad++
        }
      }
    }
    my $want_str = join(',', @$want);
    skip ($skip, $bad,0, "$name value_to_i_estimate() badness");
  }

  # infinities and fractions
  foreach my $method ('ith',
                      'value_to_i', 'value_to_i_floor', 'value_to_i_estimate') {
    if (! $seq->can($method)) {
      # skip "no $method() for $seq", 1;
    } else {
      if (defined $pos_infinity) {
        # MyTestHelpers::diag ("$method(pos_infinity) ", $name);
        $seq->$method($pos_infinity);
      }
      if (defined $neg_infinity) {
        $seq->$method($neg_infinity);
      }
      if (defined $nan) {
        $seq->$method($nan);
      }
      $seq->$method(0.5);
      $seq->$method(100.5);
      $seq->$method(-1);
      $seq->$method(-100);
      $seq->$method(-0.5);
    }
  }

  # values_min()
  {
    my $values_min = $seq->values_min;
    if (defined $values_min) {
      foreach my $value (@$want) {
        if ($value < $values_min) {
          MyTestHelpers::diag ($name, " value $value less than values_min=$values_min");
          $good = 0;
        }
      }
    }
  }

  ### pred() infinities: $name
  if (! $seq->can('pred')) {
    # MyTestHelpers::diag ("$name -- no pred()");
  } else {

    if (defined $pos_infinity) {
      $seq->pred($pos_infinity);
    }
    if (defined $neg_infinity) {
      $seq->pred($neg_infinity);
    }
    if (defined $nan) {
      if ($seq->pred($nan)) {
        $good = 0;
        MyTestHelpers::diag ($name, " -- pred(nan) should be false");
      }
      if ($seq->pred(-$nan)) {
        $good = 0;
        MyTestHelpers::diag ($name, " -- pred(-nan) should be false");
      }
    }

    {
      my $count = 0;
      foreach my $value (@$want) {
        if (! $seq->pred($value)) {
          $good = 0;
          MyTestHelpers::diag ($name, " -- pred($value) false");
          last if $count++ > 10;
        }
      }
    }

    if ($seq->characteristic('count')) {
      # MyTestHelpers::diag ($name, "-- no pred() on characteristic(count)");
    } elsif ($seq->characteristic('digits')) {
      # MyTestHelpers::diag ($name, "-- no pred() on characteristic(digits)");
    } elsif (! $seq->characteristic('increasing')) {
      # MyTestHelpers::diag ($name, "-- no pred() on not characteristic(increasing)");
    } elsif ($seq->characteristic('modulus')) {
      # MyTestHelpers::diag ($name, "-- no pred() on characteristic(modulus)");
    } else {

      if ($hi > 1000) {
        $hi = 1000;
        $want = [ grep {$_<=$hi} @$want ];
      }
      my @got;
      my $pred_lo = _min(@$want);
      my $pred_hi = $want->[-1];
      for (my $value = $pred_lo; $value <= $pred_hi; $value += 0.5) {
        ### $value
        if ($seq->pred($value)) {
          push @got, $value;
        }
      }
      _delete_duplicates($want);
      #### $want
      my $got = \@got;
      my $diff = diff_nums($got, $want);
      ok ($diff, undef, "$class pred() lo=$lo hi=$hi");
      if (defined $diff) {
        MyTestHelpers::diag ("got len ".scalar(@$got));
        MyTestHelpers::diag ("want len ".scalar(@$want));
        if ($#$got > 200) { $#$got = 200 }
        if ($#$want > 200) { $#$want = 200 }
        MyTestHelpers::diag ("got  ". join(',', map {defined() ? $_ : 'undef'} @$got));
        MyTestHelpers::diag ("want ". join(',', map {defined() ? $_ : 'undef'} @$want));
      }
    }
  }

  ok ($good, 1, $name);
}

#------------------------------------------------------------------------------

# MyTestHelpers::diag ("Math::Prime::XS version ", Math::Prime::XS->VERSION);

sub equal {
  my ($x,$y) = @_;
  return ((defined $x && defined $y && $x == $y)
          || (! defined $x && ! defined $y));
}

exit 0;
