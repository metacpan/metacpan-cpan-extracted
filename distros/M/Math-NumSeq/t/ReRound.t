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
plan tests => 106;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::ReRound;

# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 74;
  ok ($Math::NumSeq::ReRound::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::ReRound->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::ReRound->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::ReRound->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# by sieve

{
  my @sieve = (1 .. 500);
  {
    my @take;
    for (my $step = 1; $step <= $#sieve; $step++) {
      push @take, shift @sieve; # take first
      for (my $i = $step-1; $i <= $#sieve; $i += $step-1) {
        splice @sieve, $i, 1;
      }
    }
    @sieve = (@take, @sieve);
  }
  my @got;
  my $seq = Math::NumSeq::ReRound->new;
  while (@got < @sieve) {
    my ($i, $value) = $seq->next;
    push @got, $value;
  }

  my $got = join(',', @got);
  my $sieve = join(',', @sieve);
  ok ($got, $sieve);
}

#------------------------------------------------------------------------------
# Flavius Josephus sieve

{
  my @sieve = (1 .. 500);
  for (my $step = 1; $step <= $#sieve; ) {
    $step++;
    for (my $i = $step-1; $i <= $#sieve; $i += $step-1) {
      splice @sieve, $i, 1;
    }
  }

  my @got;
  my $seq = Math::NumSeq::ReRound->new (extra_multiples => 1);
  while (@got < @sieve) {
    my ($i, $value) = $seq->next;
    push @got, $value;
  }

  my $got = join(',', @got);
  my $sieve = join(',', @sieve);
  ok ($got, $sieve);
}

#------------------------------------------------------------------------------
# Flavius Josephus round down from squares

{
  my $seq = Math::NumSeq::ReRound->new (extra_multiples => 1);
  for my $i (1 .. 100) {
    my $got = $seq->ith($i);
    my $from_square = round_down_from_square($i);
    ok ($got, $from_square);
  }
}

# i^2, round down to i-1 and if already i-1 multiple then the multiple below,
# etc down to multiple of 1 and since always a multiple of 1 then subtract 1.
sub round_down_from_square {
  my ($i) = @_;
  my $value = $i*$i;
  for ($i--; $i >= 1; $i--) {
    my $rem = $value % $i;
    if ($rem == 0) { $rem = $i; }  # 1 to $i inclusive
    $value -= $rem;
  }
  return $value;
}

exit 0;
