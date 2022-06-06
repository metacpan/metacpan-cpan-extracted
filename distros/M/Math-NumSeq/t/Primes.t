#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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
plan tests => 20;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::NumSeq::Primes;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 75;
  ok ($Math::NumSeq::Primes::VERSION, $want_version, 'VERSION variable');
  ok (Math::NumSeq::Primes->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Math::NumSeq::Primes->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Primes->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# oeis_anum()

{
  my $seq = Math::NumSeq::Primes->new;
  ok ($seq->oeis_anum, 'A000040');
}

#------------------------------------------------------------------------------
# _primes_list()

{
  my @list = Math::NumSeq::Primes::_primes_list(1,10);
  ok (join(',',@list), '2,3,5,7');
}

#------------------------------------------------------------------------------
# pred()

{
  my $seq = Math::NumSeq::Primes->new;
  { my $pred = $seq->pred (2**33-1);
    ok ($pred, undef);
  }
  { require Math::BigInt;
    my $value = (Math::BigInt->new(2) << 33) - 1;
    my $pred = $seq->pred ($value);
    ok ($pred, undef);
  }
}

#------------------------------------------------------------------------------
# next()

{
  my $seq = Math::NumSeq::Primes->new;
  {
    my ($i, $value) = $seq->next;
    ok ($i, 1);
    ok ($value, 2);
  }
  {
    my ($i, $value) = $seq->next;
    ok ($i, 2);
    ok ($value, 3);
  }
  {
    my ($i, $value) = $seq->next;
    ok ($i, 3);
    ok ($value, 5);
  }
  {
    my ($i, $value) = $seq->next;
    ok ($i, 4);
    ok ($value, 7);
  }
  {
    my ($i, $value) = $seq->next;
    ok ($i, 5);
    ok ($value, 11);
  }
}


#------------------------------------------------------------------------------
# value_to_i_estimate()

{
  my $seq = Math::NumSeq::Primes->new;

  {
    my $i = $seq->value_to_i_estimate(12345);
    ok ($i > 0, 1);
  }
  {
    require Math::BigInt;
    my $skip;

    # value_to_i_estimate() requires log() operator
    if (! Math::BigInt->can('blog')) {
      $skip = 'due to Math::BigInt no blog()';
    }

    my $i = 0;
    unless ($skip) {
      my $value = Math::BigInt->new(2);
      foreach (1 .. 8) { $value *= $value; }  # 2**256
      $i = $seq->value_to_i_estimate($value);
    }
    skip ($skip,
          $i > 0, 1);
  }
}

#------------------------------------------------------------------------------
exit 0;
