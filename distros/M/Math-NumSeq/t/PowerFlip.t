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
plan tests => 8;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::PowerFlip;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 74;
  ok ($Math::NumSeq::PowerFlip::VERSION, $want_version, 'VERSION variable');
  ok (Math::NumSeq::PowerFlip->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Math::NumSeq::PowerFlip->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::PowerFlip->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::PowerFlip->new;
  ok ($seq->characteristic('count'), undef, 'characteristic(count)');
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');
  ok ($seq->characteristic('smaller'), 1, 'characteristic(smaller)');
}


#------------------------------------------------------------------------------
# values are all Powerful some,2

{
  require Math::NumSeq::Powerful;
  my $powerful = Math::NumSeq::Powerful->new (powerful_type => 'all',
                                              power => 2);
  my $seq = Math::NumSeq::PowerFlip->new;
  foreach (1 .. 1000) {
    my ($i, $value) = $seq->next;
    $powerful->pred($value)
      or die "Oops, $value not Powerful all,2";
  }
  ok (1);
}

exit 0;
