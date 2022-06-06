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
plan tests => 16;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::GolombSequence;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 75;
  ok ($Math::NumSeq::GolombSequence::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::GolombSequence->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::GolombSequence->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::GolombSequence->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::GolombSequence->new;
  ok ($seq->characteristic('smaller'), 1, 'characteristic(smaller)');
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');

  ok (! $seq->characteristic('increasing'), 1,
      'characteristic(increasing) -- no');
  ok ($seq->characteristic('non_decreasing'), 1,
      'characteristic(non_decreasing) -- yes');
  ok ($seq->characteristic('increasing_from_i'), undef,
      'characteristic(increasing_from_i)');
  ok ($seq->characteristic('non_decreasing_from_i'), $seq->i_start,
      'characteristic(non_decreasing_from_i)');
}


#------------------------------------------------------------------------------
# run lengths is seq

{
  my $choices = Math::NumSeq::GolombSequence
    ->parameter_info_hash->{'using_values'}->{'choices'};
  foreach my $using_values (@$choices) {
    my $seq = Math::NumSeq::GolombSequence->new (using_values => $using_values);
    my $run = Math::NumSeq::GolombSequence->new (using_values => $using_values);
    my ($i,$prev) = $seq->next;
    my $count = 1;
    foreach (1 .. 1000) {
      ($i,my $value) = $seq->next;
      if ($value == $prev) {
        $count++;
      } else {
        ($i, my $want_count) = $run->next;
        if ($count != $want_count) {
          die "$using_values got count=$count want=$want_count";
        }
        $prev = $value;
        $count = 1;
      }
    }
    ok (1);
  }
}

#------------------------------------------------------------------------------

exit 0;


