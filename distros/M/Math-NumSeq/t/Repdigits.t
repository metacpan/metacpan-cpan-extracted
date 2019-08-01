#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2016 Kevin Ryde

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

use Math::NumSeq::Repdigits;

my $test_count = (tests => 1055)[1];
plan tests => $test_count;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 73;
  ok ($Math::NumSeq::Repdigits::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::Repdigits->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::Repdigits->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Repdigits->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic(), i_start(), parameters

{
  my $seq = Math::NumSeq::Repdigits->new;
  ok ($seq->characteristic('increasing'), 1, 'characteristic(increasing)');
  ok ($seq->characteristic('integer'),    1, 'characteristic(integer)');
  ok (! $seq->characteristic('smaller'),  1, 'characteristic(smaller)');
  ok ($seq->i_start, 0, 'i_start()');

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames),
      'radix');
}


#------------------------------------------------------------------------------
# value_to_i_floor(), value_to_i_ceil()

foreach my $radix (2,3,4,5,10,16,37) {
  my $seq = Math::NumSeq::Repdigits->new (radix => $radix);;
  ok ($seq->value_to_i_floor(0), 0);
  ok ($seq->value_to_i_floor(0.5), 0);
  ok ($seq->value_to_i_floor(1), 1);
  ok ($seq->value_to_i_floor(1.5), 1);
  if ($radix > 2) {
    ok ($seq->value_to_i_floor(2), 2, "radix=$radix");
    ok ($seq->value_to_i_floor(2.5), 2, "radix=$radix");
  }

  ok ($seq->value_to_i_ceil(0), 0);
  ok ($seq->value_to_i_ceil(0.5), 1, "radix=$radix");
  ok ($seq->value_to_i_ceil(1), 1);
  ok ($seq->value_to_i_ceil(1.5), 2);
  if ($radix > 2) {
    ok ($seq->value_to_i_ceil(2), 2, "radix=$radix");
    ok ($seq->value_to_i_ceil(2.5), 3, "radix=$radix");
  }

  foreach my $i ($radix .. 3*$radix) {
    my $value = $seq->ith($i);
    ok ($seq->value_to_i_floor($value), $i);
    ok ($seq->value_to_i_floor($value+1), $i);
    ok ($seq->value_to_i_floor($value-1), $i-1);

    ok ($seq->value_to_i_ceil($value), $i);
    ok ($seq->value_to_i_ceil($value+1), $i+1);
    ok ($seq->value_to_i_ceil($value-1), $i);
  }
}


#------------------------------------------------------------------------------
exit 0;
