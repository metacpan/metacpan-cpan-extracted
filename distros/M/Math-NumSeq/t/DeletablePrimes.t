#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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
plan tests => 6;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::DeletablePrimes;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 74;
  ok ($Math::NumSeq::DeletablePrimes::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::DeletablePrimes->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::DeletablePrimes->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::DeletablePrimes->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# pred()

foreach my $group ([ 2,
                     [ 67, 0 ],
                   ],
                   [ 10,
                     [ 2003, 0 ],
                   ]) {
  my ($radix, @elems) = @$group;
  my $seq = Math::NumSeq::DeletablePrimes->new (radix => $radix);
  foreach my $elem (@elems) {
    my ($value, $want) = @$elem;
    ok ($seq->pred($value), $want,
        "value=$value");
  }
}

exit 0;
