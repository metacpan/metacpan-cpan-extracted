#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2018, 2019, 2020 Kevin Ryde

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
plan tests => 42;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::GrayCode;

use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh', 'digit_join_lowtohigh';
use Math::PlanePath::Diagonals;
use Math::NumSeq::PlanePathTurn;

# GP-DEFINE  read("my-oeis.gp");


#------------------------------------------------------------------------------
# Helpers

# GP-Test  my(want=50*10^6);  /* more stack */  \
# GP-Test  if(default(parisizemax)<want, default(parisizemax,want)); 1

sub to_Gray_reflected {
  my ($n,$radix) = @_;
  my $digits = [ digit_split_lowtohigh($n,$radix) ];
  Math::PlanePath::GrayCode::_digits_to_gray_reflected($digits,$radix);
  return digit_join_lowtohigh($digits,$radix);
}

sub from_Gray_reflected {
  my ($n,$radix) = @_;
  my $digits = [ digit_split_lowtohigh($n,$radix) ];
  Math::PlanePath::GrayCode::_digits_from_gray_reflected($digits,$radix);
  return digit_join_lowtohigh($digits,$radix);
}


#------------------------------------------------------------------------------
# A309952 -- X coordinate, Ts

MyOEIS::compare_values
  (anum => 'A309952',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::GrayCode->new (apply_type => 'Ts');
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A064706 - binary reflected Gray twice
#
# (n XOR n>>1) XOR (n XOR n>>1) >> 1
# = n XOR n>>1 XOR n>>1 XOR n>>2
# = n XOR n>>2

MyOEIS::compare_values
  (anum => 'A064706',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, to_Gray_reflected(to_Gray_reflected($n,2),2);
     }
     return \@got;
   });

# A064707 - binary reflected UnGray twice
MyOEIS::compare_values
  (anum => 'A064707',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, from_Gray_reflected(from_Gray_reflected($n,2),2);
     }
     return \@got;
   });

# GP-DEFINE  \\ A003188
# GP-DEFINE  binary_reflected_Gray(n) = bitxor(n,n>>1);
#
# GP-DEFINE  \\ A006068
# GP-DEFINE  binary_reflected_UnGray(g) = {
# GP-DEFINE    my(v=binary(g),r=0);
# GP-DEFINE    for(i=2,#v,  \\ high to low
# GP-DEFINE        v[i] = bitxor(v[i],v[i-1]));
# GP-DEFINE    fromdigits(v,2);
# GP-DEFINE  }
# my(v=OEIS_samples("A006068")); vector(#v,n,n--; binary_reflected_UnGray(n)) == v  \\ OFFSET=0
# my(g=OEIS_bfile_gf("A006068")); g==Polrev(vector(poldegree(g)+1,n,n--;binary_reflected_UnGray(n)))
# poldegree(OEIS_bfile_gf("A006068"))
#
# GP-DEFINE  \\ double binary Gray
# GP-DEFINE  A064706(n) = binary_reflected_Gray(binary_reflected_Gray(n));
# my(v=OEIS_samples("A064706")); vector(#v,n,n--; A064706(n)) == v  \\ OFFSET=0
# my(g=OEIS_bfile_gf("A064706")); g==Polrev(vector(poldegree(g)+1,n,n--;A064706(n)))
# poldegree(OEIS_bfile_gf("A064706"))

# GP-DEFINE  \\ double binary UnGray
# GP-DEFINE  A064707(n) = {
# GP-DEFINE    my(v=binary(n));
# GP-DEFINE    for(i=3,#v,v[i]=bitxor(v[i],v[i-2]));
# GP-DEFINE    fromdigits(v,2);
# GP-DEFINE  }
# my(v=OEIS_samples("A064707")); vector(#v,n,n--; A064707(n)) == v  \\ OFFSET=0
# my(g=OEIS_bfile_gf("A064707")); g==Polrev(vector(poldegree(g)+1,n,n--;A064707(n)))
# poldegree(OEIS_bfile_gf("A064707"))
# GP-Test  vector(2^14,n,n--; A064707(A064706(n))) == \
# GP-Test  vector(2^14,n,n--; n)
# GP-Test  vector(2^14,n,n--; A064706(A064707(n))) == \
# GP-Test  vector(2^14,n,n--; n)
#
# GP-Test  /* by shifts like Jorg and Paul D. Hanna in UnGray A006068 */ \
# GP-Test  /* bit lengths of ops 1 + 2 + ... + 2^log(nlen) */ \
# GP-Test  /* so linear in nlen rounded up to next power of 2 */ \
# GP-Test  vector(2^14,n,n--; A064707(n)) == \
# GP-Test  vector(2^14,n,n--; \
# GP-Test         my(s=1,ns); while(ns=n>>(s<<=1), n=bitxor(n,ns)); n)
#
# GP-DEFINE  extract_even_bits(n) = fromdigits(digits(n,4)%2,2);
# GP-DEFINE  extract_odd_bits(n) = fromdigits(digits(n,4)>>1,2);
# GP-DEFINE  spread_even_bits(n) = fromdigits(digits(n,2),4);
# GP-DEFINE  spread_odd_bits(n) = fromdigits(digits(n,2)<<1,4);

# GP-Test  /* double binary Gray as applied to evens and odds separately */ \
# GP-Test  /* per Antti Karttunen formula in A064706 */ \
# GP-Test  vector(2^14,n,n--; A064707(n)) == \
# GP-Test  vector(2^14,n,n--; \
# GP-Test    my(e=extract_even_bits(n)); \
# GP-Test    my(o=extract_odd_bits(n)); \
# GP-Test    e=binary_reflected_UnGray(e); \
# GP-Test    o=binary_reflected_UnGray(o); \
# GP-Test    spread_even_bits(e) + spread_odd_bits(o))


#------------------------------------------------------------------------------
# A098488 - decimal modular Gray

MyOEIS::compare_values
  (anum => 'A098488',
   func => sub {
     my ($count) = @_;
     my $radix = 10;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $digits = [ digit_split_lowtohigh($n,$radix) ];
       Math::PlanePath::GrayCode::_digits_to_gray_modular($digits,$radix);
       push @got, digit_join_lowtohigh($digits,$radix);
     }
     return \@got;
   });

# A226134 - decimal modular UnGray
MyOEIS::compare_values
  (anum => 'A226134',
   func => sub {
     my ($count) = @_;
     my $radix = 10;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $digits = [ digit_split_lowtohigh($n,$radix) ];
       Math::PlanePath::GrayCode::_digits_from_gray_modular($digits,$radix);
       push @got, digit_join_lowtohigh($digits,$radix);
     }
     return \@got;
   });

# GP-DEFINE  A098488(n) = my(v=digits(n)); forstep(i=#v,2,-1, v[i]=(v[i]-v[i-1])%10); fromdigits(v);
#
# GP-Test  /* Martin Cohn, example 4 Gray column */ \
# GP-Test  my(want=[6764,6765,6766,6767,6768,6769,6760, \
# GP-Test           6860,6861,6862,6863,6864,6865], \
# GP-Test     lo=6393, hi=6405); \
# GP-Test  for(n=lo,hi, my(i=n-lo+1); \
# GP-Test    A098488(n) == want[i] || error()); \
# GP-Test  1
# GP-Test  /* Martin Cohn, example 4 matrix, for any 4-digit number */ \
# GP-Test  my(m=[1,9,0,0; 0,1,9,0; 0,0,1,9; 0,0,0,1]); \
# GP-Test  forvec(v=vector(4,i, [0,9]), \
# GP-Test    A098488(fromdigits(v)) == fromdigits((v*m)%10) || error(v*m)); \
# GP-Test  1

# GP-DEFINE  to_Gray(n,base) = {
# GP-DEFINE    my(v=digits(n,base));
# GP-DEFINE    forstep(i=#v,2,-1, v[i]=(v[i]-v[i-1])%base);
# GP-DEFINE    fromdigits(v,base);
# GP-DEFINE  }
# GP-Test  vector(10^5,n,n--; A098488(n)) == \
# GP-Test  vector(10^5,n,n--; to_Gray(n,10))

# vector(10^5,n,n--; to_Gray(n,10))


#------------------------------------------------------------------------------
# A007913 -- square free part of N
# mod 2 skip N even is Left turns

MyOEIS::compare_values
  (anum => q{A007913},  # not xreffed in GrayCode.pm
   fixup => sub {
     my ($bvalues) = @_;
     foreach (@$bvalues) { $_ %= 2; }
   },
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'GrayCode',
                                                 turn_type => 'NotStraight');
     my @got;
     while (@got < $count) {
       my ($n,$value) = $seq->next;
       my ($n2,$value2) = $seq->next;  # undouble

       push @got, $value;
       $value==$value2 || die "oops";
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A065882 -- low base4 non-zero digit
# mod 2 is NotStraight

MyOEIS::compare_values
  (anum => 'A065882',
   fixup => sub {
     my ($bvalues) = @_;
     foreach (@$bvalues) { $_ %= 2; }
   },
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'GrayCode',
                                                 turn_type => 'NotStraight');
     my @got;
     while (@got < $count) {
       my ($n,$value) = $seq->next;
       my ($n2,$value2) = $seq->next;  # undouble

       push @got, $value;
       $value==$value2 || die "oops";
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003159 -- (N+1)/2 of positions of Left turns

MyOEIS::compare_values
  (anum => 'A003159',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'GrayCode',
                                                 turn_type => 'NotStraight');
     my @got;
     while (@got < $count) {
       my ($n,$value) = $seq->next;
       my ($n2,$value2) = $seq->next;  # undouble

       if ($value) { push @got, ($n+1)/2; }
       $value==$value2 || die "oops";
     }
     return \@got;
   });

# A036554 -- (N+1)/2 of positions of Straight turns
MyOEIS::compare_values
  (anum => 'A036554',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'GrayCode',
                                                 turn_type => 'Straight');
     my @got;
     while (@got < $count) {
       my ($n,$value) = $seq->next;  # undouble
       my ($n2,$value2) = $seq->next;
       $value==$value2 || die "oops";

       if ($value) { push @got, ($n+1)/2; }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A039963 -- Left turns
MyOEIS::compare_values
  (anum => 'A039963',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'GrayCode',
                                                 turn_type => 'Left');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

# A035263 -- Left turns undoubled, skip N even
MyOEIS::compare_values
  (anum => 'A035263',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'GrayCode',
                                                 turn_type => 'Left');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;

       my ($i2,$value2) = $seq->next;  # undouble
       $value==$value2 || die "oops";
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003188 -- Gray code radix=2 is ZOrder X,Y -> Gray TsF
#                           and Gray FsT X,Y -> ZOrder
MyOEIS::compare_values
  (anum => 'A003188',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::ZOrderCurve;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'TsF');
     my $zorder_path = Math::PlanePath::ZOrderCurve->new;
     my @got;
     for (my $n = $zorder_path->n_start; @got < $count; $n++) {
       my ($x, $y) = $zorder_path->n_to_xy ($n);
       my $n = $gray_path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A003188},
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::ZOrderCurve;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'FsT');
     my $zorder_path = Math::PlanePath::ZOrderCurve->new;
     my @got;
     for (my $n = $gray_path->n_start; @got < $count; $n++) {
       my ($x, $y) = $gray_path->n_to_xy ($n);
       my $n = $zorder_path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A006068 -- UnGray, inverse Gray TsT X,Y -> ZOrder N
#                          and ZOrder X,Y -> Gray FsF
MyOEIS::compare_values
  (anum => q{A006068},
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::ZOrderCurve;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'TsF');
     my $zorder_path = Math::PlanePath::ZOrderCurve->new;
     my @got;
     for (my $n = $gray_path->n_start; @got < $count; $n++) {
       my ($x, $y) = $gray_path->n_to_xy ($n);
       my $n = $zorder_path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

# A006068 -- UnGray, ZOrder X,Y -> Gray FsT N
MyOEIS::compare_values
  (anum => q{A006068},
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::ZOrderCurve;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'FsT');
     my $zorder_path = Math::PlanePath::ZOrderCurve->new;
     my @got;
     for (my $n = $zorder_path->n_start; @got < $count; $n++) {
       my ($x, $y) = $zorder_path->n_to_xy ($n);
       my $n = $gray_path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A064707 -- permutation radix=2 TsF -> FsT
#   inverse square of A003188 Gray code

# A064706 -- permutation radix=2 FsT -> TsF
#   square of A003188 Gray code ZOrder->TsF

# not same as A100281,A100282

MyOEIS::compare_values
  (anum => q{A064707},
   func => sub {
     my ($count) = @_;
     my $TsF_path = Math::PlanePath::GrayCode->new (apply_type => 'TsF');
     my $FsT_path = Math::PlanePath::GrayCode->new (apply_type => 'FsT');
     my @got;
     for (my $n = $TsF_path->n_start; @got < $count; $n++) {
       my ($x, $y) = $TsF_path->n_to_xy ($n);
       my $n = $FsT_path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A064706},
   func => sub {
     my ($count) = @_;
     my $TsF_path = Math::PlanePath::GrayCode->new (apply_type => 'TsF');
     my $FsT_path = Math::PlanePath::GrayCode->new (apply_type => 'FsT');
     my @got;
     for (my $n = $FsT_path->n_start; @got < $count; $n++) {
       my ($x, $y) = $FsT_path->n_to_xy ($n);
       my $n = $TsF_path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

# {
#   my $seq = Math::NumSeq::OEIS->new(anum=>'A099896');
#   sub A100281_by_twice {
#     my ($i) = @_;
#     $i = $seq->ith($i);
#     if (defined $i) { $i = $seq->ith($i); }
#     return $i;
#   }
# }
# sub A100281_by_func {
#   my ($i) = @_;
#   $i = ($i ^ ($i>>1) ^ ($i>>2));
#   $i = ($i ^ ($i>>1) ^ ($i>>2));
#   return $i;
# }


#------------------------------------------------------------------------------
# A099896 -- permutation Peano radix=2 -> Gray sF, from N=1 onwards
#  n XOR [n/2] XOR [n/4]
#  1, 3, 2, 7, 6, 4, 5, 14, 15, 13, 12, 9, 8, 10, 11, 28, 29, 31, 30, 27,
# to_gray = n xor n/2

# PeanoCurve radix=2
#
#        54--55  49--48  43--42  44--45  64--65  71--70  93--92  90--91 493-492
#         |       |           |       |       |       |   |       |       |
#        53--52  50--51  40--41  47--46  67--66  68--69  94--95  89--88 494-495
#
#        56--57  63--62  37--36  34--35  78--79  73--72  83--82  84--85 483-482
#             |       |   |       |       |       |           |       |       |
#        59--58  60--61  38--39  33--32  77--76  74--75  80--81  87--86 480-481
#
#        13--12  10--11  16--17  23--22 123-122 124-125 102-103  97--96 470-471
#         |       |           |       |       |       |   |       |       |
#        14--15   9-- 8  19--18  20--21 120-121 127-126 101-100  98--99 469-468
#
#         3-- 2   4-- 5  30--31  25--24 117-116 114-115 104-105 111-110 472-473
#             |       |   |       |       |       |           |       |       |
#         0-- 1   7-- 6  29--28  26--27 118-119 113-112 107-106 108-109 475-474

# apply_type => "sF"
#
#  7  |  32--33  37--36  52--53  49--48
#     |    /       \       /       \
#  6  |  34--35  39--38  54--55  51--50
#     |
#  5  |  42--43  47--46  62--63  59--58
#     |    \       /       \       /
#  4  |  40--41  45--44  60--61  57--56
#     |
#  3  |   8-- 9  13--12  28--29  25--24
#     |    /       \       /       \
#  2  |  10--11  15--14  30--31  27--26
#     |
#  1  |   2-- 3   7-- 6  22--23  19--18
#     |    \       /       \       /
# Y=0 |   0-- 1   5-- 4  20--21  17--16
#     |
#     +---------------------------------
#       X=0   1   2   3   4   5   6   7

MyOEIS::compare_values
  (anum => 'A099896',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::PeanoCurve;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'sF');
     my $peano_path = Math::PlanePath::PeanoCurve->new (radix => 2);
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       my ($x, $y) = $peano_path->n_to_xy ($n);
       my $n = $gray_path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

# A100280 -- inverse
MyOEIS::compare_values
  (anum => 'A100280',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::PeanoCurve;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'sF');
     my $peano_path = Math::PlanePath::PeanoCurve->new (radix => 2);
     my @got;
     for (my $n = $gray_path->n_start; @got < $count; $n++) {
       my ($x, $y) = $gray_path->n_to_xy ($n);
       my $n = $peano_path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163233 -- permutation diagonals sF

MyOEIS::compare_values
  (anum => 'A163233',
   func => sub {
     my ($count) = @_;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'sF');
     my $diagonal_path = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $n = $diagonal_path->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal_path->n_to_xy ($n);
       my $n = $gray_path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

# A163234 -- diagonals sF inverse
MyOEIS::compare_values
  (anum => 'A163234',
   func => sub {
     my ($count) = @_;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'sF');
     my $diagonal_path = Math::PlanePath::Diagonals->new (direction => 'up',
                                                          n_start => 0);
     my @got;
     for (my $n = $gray_path->n_start; @got < $count; $n++) {
       my ($x, $y) = $gray_path->n_to_xy ($n);
       my $n = $diagonal_path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163235 -- diagonals sF, opposite side start

MyOEIS::compare_values
  (anum => 'A163235',
   func => sub {
     my ($count) = @_;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'sF');
     my $diagonal_path = Math::PlanePath::Diagonals->new (direction => 'down');
     my @got;
     for (my $n = $diagonal_path->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal_path->n_to_xy ($n);
       my $n = $gray_path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

# A163236 -- diagonals sF inverse, opposite side start
MyOEIS::compare_values
  (anum => 'A163236',
   func => sub {
     my ($count) = @_;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'sF');
     my $diagonal_path = Math::PlanePath::Diagonals->new (direction => 'down');
     my @got;
     for (my $n = $gray_path->n_start; @got < $count; $n++) {
       my ($x, $y) = $gray_path->n_to_xy ($n);
       my $n = $diagonal_path->xy_to_n ($x, $y);
       push @got, $n + $gray_path->n_start - $diagonal_path->n_start;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163237 -- diagonals sF, same side start, flip base-4 digits 2,3

sub flip_base4_23 {
  my ($n) = @_;
  my @digits = digit_split_lowtohigh($n,4);
  foreach my $digit (@digits) {
    if ($digit == 2) { $digit = 3; }
    elsif ($digit == 3) { $digit = 2; }
  }
  return digit_join_lowtohigh(\@digits,4);
}


MyOEIS::compare_values
  (anum => 'A163237',
   func => sub {
     my ($count) = @_;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'sF');
     my $diagonal_path = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $n = $diagonal_path->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal_path->n_to_xy ($n);
       my $n = $gray_path->xy_to_n ($x, $y);
       $n = flip_base4_23($n);
       push @got, $n;
     }
     return \@got;
   });

# A163238 -- inverse
MyOEIS::compare_values
  (anum => 'A163238',
   func => sub {
     my ($count) = @_;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'sF');
     my $diagonal_path = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $n = $gray_path->n_start; @got < $count; $n++) {
       my $n = flip_base4_23($n);
       my ($x, $y) = $gray_path->n_to_xy ($n);
       $n = $diagonal_path->xy_to_n ($x, $y);
       push @got, $n + $gray_path->n_start - $diagonal_path->n_start;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163239 -- diagonals sF, opposite side start, flip base-4 digits 2,3

MyOEIS::compare_values
  (anum => 'A163239',
   func => sub {
     my ($count) = @_;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'sF');
     my $diagonal_path = Math::PlanePath::Diagonals->new (direction => 'down');
     my @got;
     for (my $n = $diagonal_path->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal_path->n_to_xy ($n);
       my $n = $gray_path->xy_to_n ($x, $y);
       $n = flip_base4_23($n);
       push @got, $n;
     }
     return \@got;
   });

# A163240 -- inverse
MyOEIS::compare_values
  (anum => 'A163240',
   func => sub {
     my ($count) = @_;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'sF');
     my $diagonal_path = Math::PlanePath::Diagonals->new (direction => 'down');
     my @got;
     for (my $n = $gray_path->n_start; @got < $count; $n++) {
       my $n = flip_base4_23($n);
       my ($x, $y) = $gray_path->n_to_xy ($n);
       $n = $diagonal_path->xy_to_n ($x, $y);
       push @got, $n + $gray_path->n_start - $diagonal_path->n_start;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163242 -- sF diagonal sums

MyOEIS::compare_values
  (anum => 'A163242',
   func => sub {
     my ($count) = @_;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'sF');
     my @got;
     for (my $y = 0; @got < $count; $y++) {
       my $sum = 0;
       foreach my $i (0 .. $y) {
         $sum += $gray_path->xy_to_n ($i, $y-$i);
       }
       push @got, $sum;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163478 -- sF diagonal sums, divided by 3

MyOEIS::compare_values
  (anum => 'A163478',
   func => sub {
     my ($count) = @_;
     my $gray_path = Math::PlanePath::GrayCode->new (apply_type => 'sF');
     my @got;
     for (my $y = 0; @got < $count; $y++) {
       my $sum = 0;
       foreach my $i (0 .. $y) {
         $sum += $gray_path->xy_to_n ($i, $y-$i);
       }
       push @got, $sum / 3;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003188 - binary reflected Gray
# modular and reflected same in binary

MyOEIS::compare_values
  (anum => 'A003188',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, to_Gray_reflected($n,2);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A003188',
   func => sub {
     my ($count) = @_;
     my $radix = 2;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $digits = [ digit_split_lowtohigh($n,$radix) ];
       Math::PlanePath::GrayCode::_digits_to_gray_modular($digits,$radix);
       push @got, digit_join_lowtohigh($digits,$radix);
     }
     return \@got;
   });

# A014550 - binary Gray reflected, in binary
MyOEIS::compare_values
  (anum => 'A014550',
   func => sub {
     my ($count) = @_;
     my $radix = 2;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $digits = [ digit_split_lowtohigh($n,$radix) ];
       Math::PlanePath::GrayCode::_digits_to_gray_reflected($digits,$radix);
       push @got, digit_join_lowtohigh($digits,10);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A014550},
   func => sub {
     my ($count) = @_;
     my $radix = 2;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $digits = [ digit_split_lowtohigh($n,$radix) ];
       Math::PlanePath::GrayCode::_digits_to_gray_modular($digits,$radix);
       push @got, digit_join_lowtohigh($digits,10);
     }
     return \@got;
   });

# A006068 - binary Gray reflected inverse
MyOEIS::compare_values
  (anum => q{A006068},
   func => sub {
     my ($count) = @_;
     my $radix = 2;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $digits = [ digit_split_lowtohigh($n,$radix) ];
       Math::PlanePath::GrayCode::_digits_from_gray_reflected($digits,$radix);
       push @got, digit_join_lowtohigh($digits,$radix);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A006068},
   func => sub {
     my ($count) = @_;
     my $radix = 2;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $digits = [ digit_split_lowtohigh($n,$radix) ];
       Math::PlanePath::GrayCode::_digits_from_gray_modular($digits,$radix);
       push @got, digit_join_lowtohigh($digits,$radix);
     }
     return \@got;
   });

# binary reflected Gray code increments
# lowest 1-bit of N, and negate if bit above it is a 1
MyOEIS::compare_values
  (anum => 'A055975',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       push @got, to_Gray_reflected($n,2) - to_Gray_reflected($n-1,2);
     }
     return \@got;
   });

# A119972 - signed n according as binary reflected Gray code increment negative
# dragon curve turn(n) * n
MyOEIS::compare_values
  (anum => 'A119972',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       push @got,
         to_Gray_reflected($n,2) > to_Gray_reflected($n-1,2)
         ? $n : -$n;
     }
     return \@got;
   });

# A119974 - insert 0s into A119972 ...
# https://oeis.org/A119974/table
#
# A220466 - something bit wise crossreffed from increments A055975 ...


#------------------------------------------------------------------------------
# A105530 - ternary Gray modular

MyOEIS::compare_values
  (anum => 'A105530',
   func => sub {
     my ($count) = @_;
     my $radix = 3;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $digits = [ digit_split_lowtohigh($n,$radix) ];
       Math::PlanePath::GrayCode::_digits_to_gray_modular($digits,$radix);
       push @got, digit_join_lowtohigh($digits,$radix);
     }
     return \@got;
   });

# A105529 - ternary Gray modular inverse
MyOEIS::compare_values
  (anum => 'A105529',
   func => sub {
     my ($count) = @_;
     my $radix = 3;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $digits = [ digit_split_lowtohigh($n,$radix) ];
       Math::PlanePath::GrayCode::_digits_from_gray_modular($digits,$radix);
       push @got, digit_join_lowtohigh($digits,$radix);
     }
     return \@got;
   });

# GP-DEFINE  A105530(n) = my(v=digits(n,3)); forstep(i=#v,2,-1, v[i]=(v[i]-v[i-1])%3); fromdigits(v,3);
# my(v=OEIS_samples("A105530")); vector(#v,n,n--; A105530(n)) == v  \\ OFFSET=0
# my(g=OEIS_bfile_gf("A105530")); g==Polrev(vector(poldegree(g)+1,n,n--;A105530(n)))
# poldegree(OEIS_bfile_gf("A105530"))
# GP-Test  vector(3^5,n,n--; A105530(n)) == \
# GP-Test  vector(3^5,n,n--; to_Gray(n,3))

# vector(20,n, to_Gray(n,4))
# vector(20,n, to_Gray(n,5))
# not in OEIS: 1, 2, 3, 7, 4, 5, 6, 10, 11, 8, 9, 13, 14, 15, 12, 28, 29, 30, 31, 19
# not in OEIS: 1, 2, 3, 4, 9, 5, 6, 7, 8, 13, 14, 10, 11, 12, 17, 18, 19, 15, 16, 21


#------------------------------------------------------------------------------
# A128173 - ternary Gray reflected
# odd radix to and from are the same

MyOEIS::compare_values
  (anum => 'A128173',
   func => sub {
     my ($count) = @_;
     my $radix = 3;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $digits = [ digit_split_lowtohigh($n,$radix) ];
       Math::PlanePath::GrayCode::_digits_to_gray_reflected($digits,$radix);
       push @got, digit_join_lowtohigh($digits,$radix);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A128173},
   func => sub {
     my ($count) = @_;
     my $radix = 3;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $digits = [ digit_split_lowtohigh($n,$radix) ];
       Math::PlanePath::GrayCode::_digits_from_gray_reflected($digits,$radix);
       push @got, digit_join_lowtohigh($digits,$radix);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003100 - decimal Gray reflected

MyOEIS::compare_values
  (anum => 'A003100',
   func => sub {
     my ($count) = @_;
     my $radix = 10;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $digits = [ digit_split_lowtohigh($n,$radix) ];
       Math::PlanePath::GrayCode::_digits_to_gray_reflected($digits,$radix);
       push @got, digit_join_lowtohigh($digits,$radix);
     }
     return \@got;
   });

# A174025 - decimal Gray reflected inverse
MyOEIS::compare_values
  (anum => 'A174025',
   func => sub {
     my ($count) = @_;
     my $radix = 10;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $digits = [ digit_split_lowtohigh($n,$radix) ];
       Math::PlanePath::GrayCode::_digits_from_gray_reflected($digits,$radix);
       push @got, digit_join_lowtohigh($digits,$radix);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
