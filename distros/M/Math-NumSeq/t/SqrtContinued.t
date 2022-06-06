#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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
plan tests => 402;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use List::Util 'min','max';
use Math::NumSeq::SqrtContinued;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 75;
  ok ($Math::NumSeq::SqrtContinued::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::SqrtContinued->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::SqrtContinued->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::SqrtContinued->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# values_min(), values_max()

foreach my $sqrt (2 .. 200) {
  my $seq = Math::NumSeq::SqrtContinued->new (sqrt => $sqrt);
  my $values_min = $seq->values_min;
  my $values_max = $seq->values_max;

  my @values;
  foreach (1 .. 100) {
    my ($i,$value) = $seq->next or last;
    push @values, $value;
  }
  my $saw_values_min = min(@values);
  my $saw_values_max = max(@values);

  ok ($values_min, $saw_values_min);
  ok ($values_max, $saw_values_max);
}


exit 0;


