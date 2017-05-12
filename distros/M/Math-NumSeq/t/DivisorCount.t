#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

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

use Math::NumSeq::DivisorCount;

plan tests => 9;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 72;
  ok ($Math::NumSeq::DivisorCount::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::DivisorCount->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::DivisorCount->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::DivisorCount->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic()

my $seq = Math::NumSeq::DivisorCount->new;
ok ($seq->characteristic('count'), 1, 'characteristic(count)');
ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');

ok ($seq->ith(0), 0, 'ith(0)');
ok ($seq->ith(-1), 1, 'ith(-1)');
ok ($seq->ith(-6), 4, 'ith(-6)');

exit 0;


