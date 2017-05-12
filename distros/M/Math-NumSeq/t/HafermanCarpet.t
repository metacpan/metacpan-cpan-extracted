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

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::HafermanCarpet;

# uncomment this to run the ### lines
#use Devel::Comments;

my $test_count = (tests => 22)[1];
plan tests => $test_count;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 72;
  ok ($Math::NumSeq::HafermanCarpet::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::HafermanCarpet->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::HafermanCarpet->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::HafermanCarpet->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::HafermanCarpet->new;
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
# sample values from the POD docs

foreach my $initial_value (0, 1) {
  my $seq = Math::NumSeq::HafermanCarpet->new
    (initial_value => $initial_value);

  ok (7*81 + 4*9 + 6, 609);
  ok ($seq->ith(609), 1);

  ok (4*81 + 3*9 + 6, 357);
  ok ($seq->ith(357), 0);

  ok (6*9 + 4, 58);
  ok ($seq->ith(58), $initial_value);
}

#------------------------------------------------------------------------------
exit 0;
