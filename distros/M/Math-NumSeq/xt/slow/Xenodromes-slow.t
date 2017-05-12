#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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
plan tests => 8;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::Xenodromes;

# uncomment this to run the ### lines
#use Smart::Comments;

#------------------------------------------------------------------------------
# values are all Powerful some,2

foreach my $radix (2 .. 10) {
  my $seq = Math::NumSeq::Xenodromes->new (radix => $radix);
  my $want_i = 0;
  my $prev = -1;
  foreach (1 .. $radix ** 5) {
    my ($i, $value) = $seq->next
      or last;
    $i == $want_i or die "i=$i cf want_i=$want_i";
    $want_i++;

    my $ith_value = $seq->ith($i);
    $value == $ith_value or die;

    for ($prev++; $prev < $value; $prev++) {
      if ($seq->pred($prev)) {
        die "pred($value) true cf value=$value";
      }
    }
    $prev = $value;
  }
  ok (1, 1, "radix=$radix");
}

exit 0;
