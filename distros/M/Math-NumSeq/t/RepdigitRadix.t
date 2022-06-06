#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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
plan tests => 1515;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::NumSeq::RepdigitRadix;

# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 75;
  ok ($Math::NumSeq::RepdigitRadix::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::RepdigitRadix->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::RepdigitRadix->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::RepdigitRadix->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}



#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::RepdigitRadix->new;
  ok ($seq->characteristic('digits'), undef, 'characteristic(digits)');
  ok ($seq->characteristic('smaller'), 1, 'characteristic(smaller)');
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');

  ok (! $seq->characteristic('increasing'), 1,
      'characteristic(increasing)');
  ok (! $seq->characteristic('non_decreasing'), 1,
      'characteristic(non_decreasing)');
  ok ($seq->characteristic('increasing_from_i'), undef,
      'characteristic(increasing_from_i)');
  ok ($seq->characteristic('non_decreasing_from_i'), undef,
      'characteristic(non_decreasing_from_i)');
}


#------------------------------------------------------------------------------
# next() and ith()

sub is_a_repdigit {
  my ($n, $radix) = @_;
  ### is_a_repdigit: "$n, $radix"

  if ($radix < 2) {
    die "radix < 2";
  }
  if ($n == 0) {
    return 1;
  }

  my $digit = $n % $radix;
  for (;;) {
    $n = int($n/$radix);
    if ($n) {
      if (($n % $radix) != $digit) {
        ### no ...
        return 0;
      }
    } else {
        ### yes ...
      return 1;
    }
  }
}

{
  my $seq = Math::NumSeq::RepdigitRadix->new;
  foreach my $i ($seq->i_start .. 500) {
    my ($got_i, $radix) = $seq->next;
    ok ($got_i, $i, "next() i");
    ok ($radix == 0 || is_a_repdigit($i,$radix));

    my $ith_radix = $seq->ith($i);
    ok ($radix, $ith_radix, "ith($i) value");
  }
}

#------------------------------------------------------------------------------
# ith() on BigInt

{
  my $seq = Math::NumSeq::RepdigitRadix->new;
  my $small = 123;
  require Math::BigInt;
  my $big = Math::BigInt->new(123);
  ok ($seq->ith($big), $seq->ith($small));
}

exit 0;
