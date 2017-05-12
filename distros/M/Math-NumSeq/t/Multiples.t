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

use Math::NumSeq::Multiples;

my $test_count = (tests => 41)[1];
plan tests => $test_count;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 72;
  ok ($Math::NumSeq::Multiples::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::Multiples->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::Multiples->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Multiples->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic(), i_start(), parameters

{
  my $seq = Math::NumSeq::Multiples->new (multiples => 29);
  ok ($seq->i_start, 0, 'i_start()');
  ok ($seq->characteristic('digits'), undef, 'characteristic(digits)');
  ok (! $seq->characteristic('count'), 1, 'characteristic(count)');
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');
  ok (! $seq->characteristic('smaller'), 1, 'characteristic(smaller)');

  ok ($seq->characteristic('increasing'), 1,
      'characteristic(increasing)');
  ok ($seq->characteristic('non_decreasing'), 1,
      'characteristic(non_decreasing)');

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames),
      'multiples');
}

{
  my $seq = Math::NumSeq::Multiples->new (multiples => 1.5);
  ok ($seq->characteristic('digits'), undef, 'characteristic(digits)');
  ok (! $seq->characteristic('count'), 1, 'characteristic(count)');
  ok (! $seq->characteristic('integer'), 1, 'characteristic(integer)');
  ok (! $seq->characteristic('smaller'), 1, 'characteristic(smaller)');
}

{
  my $seq = Math::NumSeq::Multiples->new (multiples => 0.25);
  ok ($seq->characteristic('digits'), undef, 'characteristic(digits)');
  ok (! $seq->characteristic('count'), 1, 'characteristic(count)');
  ok (! $seq->characteristic('integer'), 1, 'characteristic(integer)');
  ok (! $seq->characteristic('smaller'), 1, 'characteristic(smaller)');

  ok ($seq->characteristic('increasing'), 1,
      'characteristic(increasing)');
  ok ($seq->characteristic('non_decreasing'), 1,
      'characteristic(non_decreasing)');
}

#------------------------------------------------------------------------------
# value_to_i_estimate

{
  my $seq = Math::NumSeq::Multiples->new (multiples => 10);
  ok ($seq->value_to_i_estimate(30), 3);
}

{
  my $seq = Math::NumSeq::Multiples->new (multiples => 0);
  my $i = $seq->value_to_i_estimate(123);
  require POSIX;
  ok ($i >= POSIX::DBL_MAX(), 1);
}


#------------------------------------------------------------------------------
# value_to_i_floor()

{
  my $seq = Math::NumSeq::Multiples->new (multiples => 10);

  ok ($seq->value_to_i_floor(0), 0);
  ok ($seq->value_to_i_floor(0.5), 0);
  ok ($seq->value_to_i_floor(1), 0);

  ok ($seq->value_to_i_floor(9.5), 0);
  ok ($seq->value_to_i_floor(10), 1);
  ok ($seq->value_to_i_floor(10.5), 1);

  ok ($seq->value_to_i_floor(59.5), 5);
  ok ($seq->value_to_i_floor(60), 6);
  ok ($seq->value_to_i_floor(60.5), 6);

  ok ($seq->value_to_i_floor(-0.5), -1);
  ok ($seq->value_to_i_floor(-1), -1);

  ok ($seq->value_to_i_floor(-9.5), -1);
  ok ($seq->value_to_i_floor(-10), -1);
  ok ($seq->value_to_i_floor(-10.5), -2);

  ok ($seq->value_to_i_floor(-59.5), -6);
  ok ($seq->value_to_i_floor(-60), -6);
  ok ($seq->value_to_i_floor(-60.5), -7);
}


exit 0;


