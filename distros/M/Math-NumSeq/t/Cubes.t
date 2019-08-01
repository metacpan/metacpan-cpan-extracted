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
plan tests => 77;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::Cubes;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 73;
  ok ($Math::NumSeq::Cubes::VERSION, $want_version, 'VERSION variable');
  ok (Math::NumSeq::Cubes->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Math::NumSeq::Cubes->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Cubes->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::Cubes->new;
  ok ($seq->i_start, 0, 'i_start()');

  ok (! $seq->characteristic('count'), 1, 'characteristic(count)');
  ok ($seq->characteristic('digits'), undef, 'characteristic(digits)');
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');
  ok (! $seq->characteristic('smaller'), 1, 'characteristic(smaller)');

  ok ($seq->characteristic('increasing'), 1, 'characteristic(increasing)');
  ok ($seq->characteristic('non_decreasing'), 1, 'characteristic(non_decreasing)');
  ok ($seq->characteristic('increasing_from_i'), $seq->i_start);
  ok ($seq->characteristic('non_decreasing_from_i'), $seq->i_start);

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames),
      '');
}


#------------------------------------------------------------------------------
# pred()

{
  my $seq = Math::NumSeq::Cubes->new;
  ok (!! $seq->pred(27),
      1,
      'pred() 27 is cube');

}


#------------------------------------------------------------------------------
# value_to_i_floor()

{
  my $seq = Math::NumSeq::Cubes->new;
  ok ($seq->value_to_i_floor(0), 0);
  ok ($seq->value_to_i_floor(0.5), 0);
  ok ($seq->value_to_i_floor(1), 1);
  ok ($seq->value_to_i_floor(1.5), 1);
  ok ($seq->value_to_i_floor(2), 1);
  ok ($seq->value_to_i_floor(7.5), 1);
  ok ($seq->value_to_i_floor(8), 2);
  ok ($seq->value_to_i_floor(8.5), 2);
  ok ($seq->value_to_i_floor(63.5), 3);
  ok ($seq->value_to_i_floor(64), 4);
  ok ($seq->value_to_i_floor(64.5), 4);

  ok ($seq->value_to_i_floor(-0.5), -1);
  ok ($seq->value_to_i_floor(-1), -1);

  ok ($seq->value_to_i_floor(-1.5), -2);
  ok ($seq->value_to_i_floor(-7.5), -2);
  ok ($seq->value_to_i_floor(-8), -2);
  ok ($seq->value_to_i_floor(-8.5), -3);

  ok ($seq->value_to_i_floor(-63.5), -4);
  ok ($seq->value_to_i_floor(-64), -4);
  ok ($seq->value_to_i_floor(-64.5), -5);
}


#------------------------------------------------------------------------------
# value_to_i_ceil()

{
  my $seq = Math::NumSeq::Cubes->new;
  ok ($seq->value_to_i_ceil(0), 0);
  ok ($seq->value_to_i_ceil(0.5), 1);
  ok ($seq->value_to_i_ceil(1), 1);
  ok ($seq->value_to_i_ceil(1.5), 2);
  ok ($seq->value_to_i_ceil(2), 2);
  ok ($seq->value_to_i_ceil(7.5), 2);
  ok ($seq->value_to_i_ceil(8), 2);
  ok ($seq->value_to_i_ceil(8.5), 3);
  ok ($seq->value_to_i_ceil(63.5), 4);
  ok ($seq->value_to_i_ceil(64), 4);
  ok ($seq->value_to_i_ceil(64.5), 5);

  ok ($seq->value_to_i_ceil(-0.5), 0);
  ok ($seq->value_to_i_ceil(-1), -1);

  ok ($seq->value_to_i_ceil(-1.5), -1);
  ok ($seq->value_to_i_ceil(-7.5), -1);
  ok ($seq->value_to_i_ceil(-8), -2);
  ok ($seq->value_to_i_ceil(-8.5), -2);

  ok ($seq->value_to_i_ceil(-63.5), -3);
  ok ($seq->value_to_i_ceil(-64), -4);
  ok ($seq->value_to_i_ceil(-64.5), -4);
}


#------------------------------------------------------------------------------
# seek_to_value()

{
  my $seq = Math::NumSeq::Cubes->new;
  {
    $seq->seek_to_value(-27);
    my ($i, $value) = $seq->next;
    ok ($i, -3);
    ok ($value, -27);
  }
  {
    $seq->seek_to_value(-27.5);
    my ($i, $value) = $seq->next;
    ok ($i, -3);
    ok ($value, -27);
  }
  {
    $seq->seek_to_value(-26.5);
    my ($i, $value) = $seq->next;
    ok ($i, -2);
    ok ($value, -8);
  }
  {
    $seq->seek_to_value(-0.5);
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
    ok ($value, 1);
  }
  {
    $seq->seek_to_value(1);
    my ($i, $value) = $seq->next;
    ok ($i, 1);
    ok ($value, 1);
  }
  {
    $seq->seek_to_value(1.5);
    my ($i, $value) = $seq->next;
    ok ($i, 2);
    ok ($value, 8);
  }
  {
    $seq->seek_to_value(7.5);
    my ($i, $value) = $seq->next;
    ok ($i, 2);
    ok ($value, 8);
  }
  {
    $seq->seek_to_value(8);
    my ($i, $value) = $seq->next;
    ok ($i, 2);
    ok ($value, 8);
  }
  {
    $seq->seek_to_value(1000.5);
    my ($i, $value) = $seq->next;
    ok ($i, 11);
    ok ($value, 11*11*11);
  }
}


#------------------------------------------------------------------------------
# bit of a diagnostic to see how accurate cbrt() is, for the cbrt(27) not an
# integer struck in the past
{
  require Math::Libm;
  my $n = 27;
  $n = Math::Libm::cbrt ($n);
  MyTestHelpers::diag("cbrt(27) is $n");
  my $i = int($n);
  MyTestHelpers::diag("int() is $i");
  my $eq = ($n == int($n));
  MyTestHelpers::diag("equal is '$eq'");
}

exit 0;


