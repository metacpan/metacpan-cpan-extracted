#!/usr/bin/perl -w

# Copyright 2013, 2014 Kevin Ryde

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
plan tests => 90;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::LucasNumbers;

# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 72;
  ok ($Math::NumSeq::LucasNumbers::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::LucasNumbers->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::LucasNumbers->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::LucasNumbers->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# POD docs fomulas L <-> F

{
  require Math::NumSeq::Fibonacci;
  my $fib = Math::NumSeq::Fibonacci->new;
  my $luc = Math::NumSeq::LucasNumbers->new;
  for (my $i = 3; $i < 12; $i++) {
    my ($F0,$F1) = $fib->ith_pair($i);
    my ($L0,$L1) = $luc->ith_pair($i);

    ok (( -$L0 + 2*$L1)/5, $F0);     # F[k]   = ( - L[k] + 2*L[k+1]) / 5
    ok ((2*$L0 +   $L1)/5, $F1);     # F[k+1] = ( 2*L[k] +   L[k+1]) / 5
    ok (($F0 + $L0)/2, $F1);       # F[k+1] = (F[k] + L[k])/2

    ok ( -$F0 + 2*$F1, $L0);     # L[k]   =  - F[k] + 2*F[k+1]
    ok (2*$F0 +   $F1, $L1);     # L[k+1] =  2*F[k] +   F[k+1]
    ok ((5*$F0 + $L0)/2, $L1);     # L[k+1] = (5*F[k] + L[k]) / 2
  }
}

#------------------------------------------------------------------------------
# characteristic(), i_start(), parameters

{
  my $seq = Math::NumSeq::LucasNumbers->new;
  ok ($seq->characteristic('digits'), undef, 'characteristic(digits)');
  ok (! $seq->characteristic('smaller'), 1, 'characteristic(smaller)');
  ok (! $seq->characteristic('count'), 1, 'characteristic(count)');
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');

  ok ($seq->characteristic('increasing'), 1,
      'characteristic(increasing)');
  ok ($seq->characteristic('non_decreasing'), 1,
      'characteristic(non_decreasing)');

  ok ($seq->characteristic('increasing_from_i'), $seq->i_start,
      'characteristic(increasing_from_i)');
  ok ($seq->characteristic('non_decreasing_from_i'), $seq->i_start,
      'characteristic(non_decreasing_from_i)');

  ok ($seq->i_start, 1, 'i_start()');

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames),
      '');
}

#------------------------------------------------------------------------------
# negative ith() and ith_pair()

{
  my $seq = Math::NumSeq::LucasNumbers->new;
  my $i = 1;
  my $want_f0 = 1;  # L[1] = 1
  my $want_f1 = 3;  # L[2] = 3
  for (my $i = 1; $i > -10; $i--) {
    {
      my $got_f0 = $seq->ith($i);
      ok ($got_f0, $want_f0);
    }
    {
      my ($got_f0, $got_f1) = $seq->ith_pair($i);
      ok ("$got_f0,$got_f1", "$want_f0,$want_f1", "ith_pair() i=$i");
    }
    # fprev + f0 = f1, so fprev = f1-f0
    ($want_f0, $want_f1) = ($want_f1 - $want_f0, $want_f0);
  }
}

#------------------------------------------------------------------------------
exit 0;
