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
plan tests => 6;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::NumSeq::SafePrimes;

# uncomment this to run the ### lines
#use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 75;
  ok ($Math::NumSeq::SafePrimes::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::SafePrimes->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::SafePrimes->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::SafePrimes->VERSION($check_version); 1 },
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
  my $seq = Math::NumSeq::SafePrimes->new;
  ok ($seq->oeis_anum, 'A005385');
  ok (collect($seq), '1,2,3,4,5 -- 5,7,11,23,47');
}

exit 0;
