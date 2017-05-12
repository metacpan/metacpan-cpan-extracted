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

use Math::NumSeq::Pronic;

my $test_count = (tests => 47)[1];
plan tests => $test_count;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 72;
  ok ($Math::NumSeq::Pronic::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::Pronic->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::Pronic->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Pronic->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic(), i_start(), parameters

{
  my $seq = Math::NumSeq::Pronic->new;
  ok ($seq->characteristic('increasing'), 1, 'characteristic(increasing)');
  ok ($seq->characteristic('integer'),    1, 'characteristic(integer)');
  ok (! $seq->characteristic('smaller'),  1, 'characteristic(smaller)');
  ok ($seq->i_start, 0, 'i_start()');

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames),
      '');
}


#------------------------------------------------------------------------------
# value_to_i_floor()

{
  my $seq = Math::NumSeq::Pronic->new;
  ok ($seq->value_to_i_floor(0), 0);
  ok ($seq->value_to_i_floor(0.5), 0);

  ok ($seq->value_to_i_floor(1.5), 0);
  ok ($seq->value_to_i_floor(2), 1);
  ok ($seq->value_to_i_floor(2.5), 1);

  ok ($seq->value_to_i_floor(5.5), 1);
  ok ($seq->value_to_i_floor(6), 2);
  ok ($seq->value_to_i_floor(6.5), 2);

  ok ($seq->value_to_i_floor(-0.5), 0);
  ok ($seq->value_to_i_floor(-100), 0);
}

#------------------------------------------------------------------------------
# value_to_i_ceil()

{
  my $seq = Math::NumSeq::Pronic->new;
  ok ($seq->value_to_i_ceil(0), 0);
  ok ($seq->value_to_i_ceil(0.5), 1);

  ok ($seq->value_to_i_ceil(1.5), 1);
  ok ($seq->value_to_i_ceil(2), 1);
  ok ($seq->value_to_i_ceil(2.5), 2);

  ok ($seq->value_to_i_ceil(5.5), 2);
  ok ($seq->value_to_i_ceil(6), 2);
  ok ($seq->value_to_i_ceil(6.5), 3);

  ok ($seq->value_to_i_ceil(-0.5), 0);
  ok ($seq->value_to_i_ceil(-100), 0);
}

#------------------------------------------------------------------------------
# seek_to_i()

{
  my $seq = Math::NumSeq::Pronic->new;
  {
    $seq->seek_to_i(0);
    my ($i, $value) = $seq->next;
    ok ($i, 0);
    ok ($value, 0);
  }
  {
    $seq->seek_to_i(10);
    my ($i, $value) = $seq->next;
    ok ($i, 10);
    ok ($value, 10*11);
  }
}

#------------------------------------------------------------------------------
# seek_to_value()

{
  my $seq = Math::NumSeq::Pronic->new;
  {
    $seq->seek_to_value(-123);
    my ($i, $value) = $seq->next;
    ok ($i, 0);
    ok ($value, 0);
  }
  {
    $seq->seek_to_value(0);
    my ($i, $value) = $seq->next;
    ok ($i, 0);
    ok ($value, 0);
  }
  {
    $seq->seek_to_value(0.5);
    my ($i, $value) = $seq->next;
    ok ($i, 1);
    ok ($value, 2);
  }
  {
    $seq->seek_to_value(1.5);
    my ($i, $value) = $seq->next;
    ok ($i, 1);
    ok ($value, 2);
  }
  {
    $seq->seek_to_value(2);
    my ($i, $value) = $seq->next;
    ok ($i, 1);
    ok ($value, 2);
  }
  {
    $seq->seek_to_value(2.5);
    my ($i, $value) = $seq->next;
    ok ($i, 2);
    ok ($value, 6);
  }
  {
    $seq->seek_to_value(20.5);
    my ($i, $value) = $seq->next;
    ok ($i, 5);
    ok ($value, 30);
  }
}

#------------------------------------------------------------------------------
exit 0;


