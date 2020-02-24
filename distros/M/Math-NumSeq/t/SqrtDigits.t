#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::NumSeq::SqrtDigits;

my $test_count = (tests => 50)[1];
plan tests => $test_count;

{
  require Math::BigInt;
  MyTestHelpers::diag ('Math::BigInt version ', Math::BigInt->VERSION);

  my $n = Math::BigInt->new(1);
  if (! $n->can('bsqrt')) {
    MyTestHelpers::diag ('skip due to Math::BigInt no bsqrt()');
    foreach (1 .. $test_count) {
      skip ('skip due to Math::BigInt no bsqrt()', 1, 1);
    }
    exit 0;
  }
}



#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 74;
  ok ($Math::NumSeq::SqrtDigits::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::SqrtDigits->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::SqrtDigits->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::SqrtDigits->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic(), i_start(), parameters

{
  my $seq = Math::NumSeq::SqrtDigits->new;
  ok ($seq->characteristic('digits'), 10, 'characteristic(digits)');
  ok ($seq->characteristic('smaller'), 1, 'characteristic(smaller)');
  ok (! $seq->characteristic('count'), 1, 'characteristic(count)');
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');

  ok (! $seq->characteristic('increasing'), 1,
      'characteristic(increasing)');
  ok (! $seq->characteristic('non_decreasing'), 1,
      'characteristic(non_decreasing)');

  ok ($seq->characteristic('increasing_from_i'), undef,
      'characteristic(increasing_from_i)');
  ok ($seq->characteristic('non_decreasing_from_i'), undef,
      'characteristic(non_decreasing_from_i)');

  ok ($seq->i_start, 1, 'i_start()');

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames),
      'sqrt,radix');
}


#------------------------------------------------------------------------------

require Math::BigInt;
foreach my $sqrt (2,7,123456) {
  foreach my $radix (2,3,4,5,8,9,10,11,15,16,17,12345) {
    my $root = Math::BigInt->new($radix);
    $root->bpow(2 * 200);  # past the 150 digit extending step
    $root->bmul($sqrt);
    $root->bsqrt;
    my @digits;
    while ($root != 0) {
      push @digits, $root % $radix;
      $root->bdiv($radix);
    }
    @digits = reverse @digits;
    my $want = join(',',@digits);

    my $seq = Math::NumSeq::SqrtDigits->new (sqrt => $sqrt, radix => $radix);
    my @got;
    foreach (1 .. @digits) {
      my ($i,$value) = $seq->next;
      push @got, $value;
    }
    my $got = join(',',@got);

    ok ($got,$want, "sqrt($sqrt) radix $radix");
    if ($got ne $want) {
      my $i = 0;
      while ($i < length($got) && $i < length($want)) {
        if (substr($got,$i,1) ne substr($want,$i,1)) {
          MyTestHelpers::diag("differ at char $i");
          last;
        }
        $i++;
      }
    }
  }
}

exit 0;


