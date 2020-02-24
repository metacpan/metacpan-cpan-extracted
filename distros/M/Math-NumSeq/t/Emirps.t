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
plan tests => 9;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::Emirps;

# uncomment this to run the ### lines
#use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 74;
  ok ($Math::NumSeq::Emirps::VERSION, $want_version, 'VERSION variable');
  ok (Math::NumSeq::Emirps->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Math::NumSeq::Emirps->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Emirps->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::Emirps->new;
  ok ($seq->characteristic('count'), undef, 'characteristic(count)');
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');
}


#------------------------------------------------------------------------------
# _reverse_in_radix()

{
  ok (Math::NumSeq::Emirps::_reverse_in_radix(123,10),
      321);
  ok (Math::NumSeq::Emirps::_reverse_in_radix(0xAB,16),
      0xBA);
  ok (Math::NumSeq::Emirps::_reverse_in_radix(6,2),
      3);
}

exit 0;


