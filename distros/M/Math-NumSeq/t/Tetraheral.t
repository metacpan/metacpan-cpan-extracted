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
plan tests => 35;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::NumSeq::Tetrahedral;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 75;
  ok ($Math::NumSeq::Tetrahedral::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::Tetrahedral->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::Tetrahedral->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Tetrahedral->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic(), i_start(), parameters

{
  my $seq = Math::NumSeq::Tetrahedral->new;
  ok ($seq->characteristic('increasing'), 1, 'characteristic(increasing)');
  ok ($seq->characteristic('integer'),    1, 'characteristic(integer)');
  ok ($seq->i_start, 0, 'i_start()');

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames),
      '');
}


#------------------------------------------------------------------------------
# value_to_i_floor()

{
  my $seq = Math::NumSeq::Tetrahedral->new;
  ok ($seq->value_to_i_floor(0), 0);
  ok ($seq->value_to_i_floor(0.5), 0);
  ok ($seq->value_to_i_floor(1), 1);
  ok ($seq->value_to_i_floor(1.5), 1);
  ok ($seq->value_to_i_floor(2), 1);
  ok ($seq->value_to_i_floor(3.5), 1);
  ok ($seq->value_to_i_floor(4), 2);
  ok ($seq->value_to_i_floor(4.5), 2);
  ok ($seq->value_to_i_floor(55.5), 5);
  ok ($seq->value_to_i_floor(56.5), 6);
  ok ($seq->value_to_i_floor(56.5), 6);

  # T(-1) = (-1)*0*1/6 = 0
  # T(-2) = (-2)*(-1)*0/6 = 0

  ok ($seq->value_to_i_floor(-0.5), -3);
  ok ($seq->value_to_i_floor(-1), -3);
  # T(-3) = (-3)*(-2)*(-1)/6 = -1

  ok ($seq->value_to_i_floor(-1.5), -4);
  ok ($seq->value_to_i_floor(-3.5), -4);
  ok ($seq->value_to_i_floor(-4), -4);
  # T(-4) = (-4)*(-3)*(-2)/6 = -4

  ok ($seq->value_to_i_floor(-4.001), -5);
  ok ($seq->value_to_i_floor(-4.5), -5);
  ok ($seq->value_to_i_floor(-5), -5);
  ok ($seq->value_to_i_floor(-9.5), -5);
  ok ($seq->value_to_i_floor(-10), -5);
  # T(-5) = (-5)*(-4)*(-3)/6 = -10

  ok ($seq->value_to_i_floor(-10.5), -6);
  ok ($seq->value_to_i_floor(-19), -6);
  ok ($seq->value_to_i_floor(-20), -6);
  # T(-6) = (-6)*(-5)*(-4)/6 = -20

  ok ($seq->value_to_i_floor(-20.001), -7);
  ok ($seq->value_to_i_floor(-20.5), -7);
  ok ($seq->value_to_i_floor(-21), -7);
}

exit 0;


