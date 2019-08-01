#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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
plan tests => 14;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::NumSeq::TwinPrimes;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 73;
  ok ($Math::NumSeq::TwinPrimes::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::TwinPrimes->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::TwinPrimes->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::TwinPrimes->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# next()

sub collect {
  my ($seq, $count) = @_;
  my @i;
  my @values;
  foreach (1 .. ($count||5)) {
    my ($i, $value) = $seq->next
      or last;
    push @i, $i;
    push @values, $value;
  }
  return join(',',@i) . ' -- ' . join(',',@values);
}
    
{
  my $seq = Math::NumSeq::TwinPrimes->new;
  ok ($seq->oeis_anum, 'A001359');
  ok (collect($seq), '1,2,3,4,5 -- 3,5,11,17,29');
}
{
  my $seq = Math::NumSeq::TwinPrimes->new (pairs => 'first');
  ok ($seq->oeis_anum, 'A001359');
  ok (collect($seq), '1,2,3,4,5 -- 3,5,11,17,29');
}
{
  my $seq = Math::NumSeq::TwinPrimes->new (pairs => 'second');
  ok ($seq->oeis_anum, 'A006512');
  ok (collect($seq), '1,2,3,4,5 -- 5,7,13,19,31');
}
{
  my $seq = Math::NumSeq::TwinPrimes->new (pairs => 'average');
  # ok ($seq->oeis_anum, 'A014574');  # different OFFSET
  ok (collect($seq), '1,2,3,4,5 -- 4,6,12,18,30');
}
{
  my $seq = Math::NumSeq::TwinPrimes->new (pairs => 'both');
  ok ($seq->oeis_anum, 'A001097');
  ok (collect($seq,9), '1,2,3,4,5,6,7,8,9 -- 3,5,7,11,13,17,19,29,31');
}

#------------------------------------------------------------------------------
# value_to_i_estimate()

{
  require Math::NumSeq::Primes;
  my $primes = Math::NumSeq::Primes->new;
  my $twin = Math::NumSeq::TwinPrimes->new;
  my $i = $primes->value_to_i_estimate(1000);
  my $j = $twin->value_to_i_estimate(1000);
  ok ($i > $j, 1,
     "$i $j");
}

exit 0;
