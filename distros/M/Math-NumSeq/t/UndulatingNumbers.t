#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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
plan tests => 34;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::UndulatingNumbers;

# uncomment this to run the ### lines
#use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 74;
  ok ($Math::NumSeq::UndulatingNumbers::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::UndulatingNumbers->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::UndulatingNumbers->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::UndulatingNumbers->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# next() and ith() versus pred()

foreach my $including_repdigits (0, 1) {
  foreach my $radix (2 .. 16) {
    my $good = 1;

    my $hi = 1000;
    my $seq = Math::NumSeq::UndulatingNumbers->new
      (radix => $radix,
       including_repdigits => $including_repdigits);
    my @next;

    while (my ($i, $value) = $seq->next) {
      last if ($value > $hi);
      $next[$value] = 1;

      my $ith_value = $seq->ith($i);
      if ($ith_value != $value) {
        MyTestHelpers::diag ("radix=$radix,reps=$including_repdigits next_value=$value but ith($i) value=$ith_value");
        $good = 0;
      }
    }

    foreach my $value (0 .. $hi) {
      my $pred = ($seq->pred($value)?1:0);
      my $next = $next[$value] || 0;
      if ($pred != $next) {
        MyTestHelpers::diag ("radix=$radix,reps=$including_repdigits value=$value wrong pred=$pred next=$next");
        $good = 0;
        last;
      }
    }

    {
      my $want_i = -1;
      foreach my $value (0 .. $hi) {
        if ($next[$value]) {
          $want_i++;
        }
        my $got_i = $seq->value_to_i_floor($value);
        if ($got_i != $want_i) {
          MyTestHelpers::diag ("radix=$radix,reps=$including_repdigits value_to_i_floor($value)=$got_i expected i=$want_i");
          my $prev_value = $seq->ith($want_i);
          MyTestHelpers::diag ("  ith($want_i)=$prev_value");
          $good = 0;
        }
      }
    }

    ok ($good, 1, "good");
  }
}

exit 0;


