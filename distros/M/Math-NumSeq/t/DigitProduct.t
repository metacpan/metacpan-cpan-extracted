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
plan tests => 33;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::DigitProduct;

# uncomment this to run the ### lines
#use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 75;
  ok ($Math::NumSeq::DigitProduct::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::DigitProduct->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::DigitProduct->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::DigitProduct->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::DigitProduct->new;
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
# pred()

{
  foreach my $elem ([2, -1,  0],
                    [2, 0,  1],
                    [2, 1,  1],
                    [2, 2,  0],

                    [3, -1,  0],
                    [3, 0,  1],
                    [3, 1,  1],
                    [3, 2,  1],
                    [3, 3,  0],
                    [3, 4,  1],
                    [3, 5,  0],
                    [3, 6,  0],
                    [3, 7,  0],
                    [3, 8,  1],

                    [10, -1,  0],
                    [10, 0,  1],
                    [10, 1,  1],
                    [10, 2,  1],
                    [10, 9,  1],
                    [10, 10,  1],
                    [10, 11,  0],
                    [10, 12,  1],
                    [10, 4*9, 1],
                   ) {
    my ($radix, $value, $want) = @$elem;
    my $seq = Math::NumSeq::DigitProduct->new (radix => $radix);
    my $got = $seq->pred($value) ? 1 : 0;
    ok ($got, $want, "pred() radix=$radix value=$value got $got want $want");
  }
}


exit 0;


