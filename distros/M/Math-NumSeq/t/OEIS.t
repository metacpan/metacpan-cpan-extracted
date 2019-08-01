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
plan tests => 6;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::OEIS;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 73;
  ok ($Math::NumSeq::OEIS::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::OEIS->VERSION, $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::OEIS->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::OEIS->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------

{
  # 6-digits
  my $seq = Math::NumSeq::OEIS->new (anum => 'A000002');
  ok ($seq->isa('Math::NumSeq::Kolakoski') ? 1 : 0,
      1);
}

{
  # 7-digits
  my $seq = Math::NumSeq::OEIS->new (anum => 'A0000040');
  ok ($seq->isa('Math::NumSeq::Primes') ? 1 : 0,
      1);
}

#------------------------------------------------------------------------------
exit 0;


