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
plan tests => 52;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::WoodallNumbers;

# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 75;
  ok ($Math::NumSeq::WoodallNumbers::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::WoodallNumbers->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::WoodallNumbers->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::WoodallNumbers->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::WoodallNumbers->new;
  ok ($seq->i_start, 1, 'i_start()');

  ok ($seq->characteristic('digits'), undef, 'characteristic(digits)');
  ok (! $seq->characteristic('smaller'), 1, 'characteristic(smaller)');
  ok (! $seq->characteristic('count'), 1, 'characteristic(count)');
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');

  ok ($seq->characteristic('increasing'), 1,
      'characteristic(increasing)');
  ok ($seq->characteristic('non_decreasing'), 1,
      'characteristic(non_decreasing)');

  ok ($seq->characteristic('increasing_from_i'), $seq->i_start,
      'characteristic(increasing_from_i)');
  ok ($seq->characteristic('non_decreasing_from_i'), $seq->i_start,
      'characteristic(non_decreasing_from_i)');

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames),
      '');
}

#------------------------------------------------------------------------------
# seek_to_i()

{
  my $seq = Math::NumSeq::WoodallNumbers->new;
  foreach my $i (0 .. 10, 32, 64, 128) {
    $seq->seek_to_i($i);
    my ($got_i, $got_value) = $seq->next;
    ok ($got_i, $i);
    ok ($got_value, $seq->ith($i),
        "seek_to_i($i) value");
  }
}

#------------------------------------------------------------------------------
# pred()

{
  my $seq = Math::NumSeq::WoodallNumbers->new;
  ok (! $seq->pred(0), 1);
  ok ($seq->pred(1), 1);
  ok (! $seq->pred(3), 1);

  ok (! $seq->pred(6), 1);
  ok ($seq->pred(7), 1);
  ok (! $seq->pred(8), 1);

  ok (! $seq->pred(22), 1);
  ok ($seq->pred(23), 1);
  ok (! $seq->pred(24), 1);
}

#------------------------------------------------------------------------------
# value_to_i_floor()

{
  my $bad = 0;
  my $seq = Math::NumSeq::WoodallNumbers->new;
  my ($i, $value) = $seq->next;
 OUTER: foreach (1 .. 10) {
    my ($next_i, $next_value) = $seq->next;
    foreach my $try_value ($value .. $next_value-1) {
      my $got_i = $seq->value_to_i_floor($try_value);
      if ($i != $got_i) {
        MyTestHelpers::diag ("value_to_i_floor($try_value) got $got_i want $i");
        last OUTER if $bad++ > 2000;
      }
    }
    $i = $next_i;
    $value = $next_value;
  }
  ok ($bad, 0, 'value_to_i_floor()');
}


exit 0;


