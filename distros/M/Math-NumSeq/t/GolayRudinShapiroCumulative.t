#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

use Math::NumSeq::GolayRudinShapiroCumulative;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 75;
  ok ($Math::NumSeq::GolayRudinShapiroCumulative::VERSION, $want_version, 'VERSION variable');
  ok (Math::NumSeq::GolayRudinShapiroCumulative->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Math::NumSeq::GolayRudinShapiroCumulative->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::GolayRudinShapiroCumulative->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::GolayRudinShapiroCumulative->new;
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');
  ok ($seq->characteristic('smaller'), 1, 'characteristic(smaller)');
  ok ($seq->values_min, 1, 'values_min');
}


#------------------------------------------------------------------------------
# next() vs ith()

{
  my $seq = Math::NumSeq::GolayRudinShapiroCumulative->new;
  for (1 .. 2) {
    my $want_i = 0;
    for (1 .. 10000) {
      my ($i, $value) = $seq->next;
      if ($i != $want_i) {
        die "Oops, next() i=$i want_i=$want_i";
      }
      $want_i++;
      my $ith_value = $seq->ith($i);
      if ($value != $ith_value) {
        die "Oops, cumulative at i=$i next=$value ith=$ith_value";
      }
    }
    $seq->rewind;
  }
  ok (1,1);
}

exit 0;

