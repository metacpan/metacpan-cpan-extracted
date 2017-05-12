#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014 Kevin Ryde

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

use Math::NumSeq::Tribonacci;

my $test_count = (tests => 166)[1];
plan tests => $test_count;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 72;
  ok ($Math::NumSeq::Tribonacci::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::Tribonacci->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::Tribonacci->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Tribonacci->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic(), i_start(), parameters

{
  my $seq = Math::NumSeq::Tribonacci->new;
  ok (! $seq->characteristic('increasing'), 1);
  ok ($seq->characteristic('increasing_from_i'), 3);
  ok ($seq->characteristic('non_decreasing'), 1);
  ok ($seq->characteristic('integer'),    1);
  ok ($seq->i_start, 0, 'i_start()');

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames),
      '');
}


#------------------------------------------------------------------------------
# value_to_i_estimate()

{
  my $seq = Math::NumSeq::Tribonacci->new;
  ok ($seq->value_to_i_estimate(0), 0);
  ok ($seq->value_to_i_estimate(1), 2);
  ok ($seq->value_to_i_estimate(2), 4);
  ok ($seq->value_to_i_estimate(4), 5);
  ok ($seq->value_to_i_estimate(7), 6);
  ok ($seq->value_to_i_estimate(13),7);
}

#------------------------------------------------------------------------------
# next() promote to bigint

{
  my $seq = Math::NumSeq::Tribonacci->new;
  my $i;
  ($i, my $f0) = $seq->next;
  ($i, my $f1) = $seq->next;
  ($i, my $f2) = $seq->next;
  foreach (1 .. 150) {
    ($i, my $value) = $seq->next;
    my $zero = $value - $f2 - $f1 - $f0;
    ok ($zero == 0, 1, "at i=$i  zero=$zero");
    $f0 = $f1;
    $f1 = $f2;
    $f2 = $value;
  }
}


exit 0;


