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
plan tests => 15;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::LuckyNumbers;

# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 75;
  ok ($Math::NumSeq::LuckyNumbers::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::LuckyNumbers->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::LuckyNumbers->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::LuckyNumbers->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic(), i_start(), parameters

{
  my $seq = Math::NumSeq::LuckyNumbers->new;
  ok ($seq->characteristic('digits'), undef, 'characteristic(digits)');
  ok (! $seq->characteristic('smaller'), 1, 'characteristic(smaller)');
  ok (! $seq->characteristic('count'), 1, 'characteristic(count)');
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');

  ok ($seq->characteristic('increasing'), 1,
      'characteristic(increasing)');
  ok ($seq->characteristic('non_decreasing'), 1,
      'characteristic(non_decreasing)');

  ok ($seq->characteristic('increasing_from_i'), $seq->i_start,
      'characteristic(increasing_from_i)');
  ok ($seq->characteristic('non_decreasing_from_i'), $seq->i_start,
      'characteristic(non_decreasing_from_i)');

  ok ($seq->i_start, 1, 'i_start()');

  my @pnames = map {$_->{'name'}} $seq->parameter_info_list;
  ok (join(',',@pnames),
      '');
}

#------------------------------------------------------------------------------
# by actual sieve

{
  my @sieve = (map { 2*$_+1} 0 .. 500); # odd 1,3,5,7 etc
  for (my $upto = 1; $upto <= $#sieve; $upto++) {
    my $step = $sieve[$upto];
    ### $step
    for (my $i = $step-1; $i <= $#sieve; $i += $step-1) {
      splice @sieve, $i, 1;
    }
  }

  my @got;
  my $seq = Math::NumSeq::LuckyNumbers->new;
  while (@got < @sieve) {
    my ($i, $value) = $seq->next;
    push @got, $value;
  }

  my $got = join(',', @got);
  my $sieve = join(',', @sieve);
  ok ($got, $sieve);
}

#------------------------------------------------------------------------------

exit 0;
