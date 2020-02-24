#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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
plan tests => 13;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::NumSeq::Runs;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 74;
  ok ($Math::NumSeq::Runs::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::Runs->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::Runs->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Runs->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic(), i_start(), parameters

{
  my $seq = Math::NumSeq::Runs->new;
  ok ($seq->i_start, 0, 'i_start()');

  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');
  ok (! $seq->characteristic('count'), 1, 'characteristic(count)');
  ok ($seq->characteristic('digits'), undef, 'characteristic(digits)');

  ok (! $seq->characteristic('increasing'), 1,
      'characteristic(increasing)');
  ok (! $seq->characteristic('non_decreasing'), 1,
      'characteristic(non_decreasing)');

  ok ($seq->characteristic('increasing_from_i'), undef,
      'characteristic(increasing_from_i)');
  ok ($seq->characteristic('non_decreasing_from_i'), undef,
      'characteristic(non_decreasing_from_i)');

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames),
      'runs_type');
}

exit 0;


