#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

require 5;
use strict;
use List::Util 'min','max';

# uncomment this to run the ### lines
#use Smart::Comments;

{
  # period vs 2*sqrt

  require Math::NumSeq::SqrtContinuedPeriod;
  my $seq = Math::NumSeq::SqrtContinuedPeriod->new;
  foreach my $sqrt (2 .. 20000) {
    my $period = $seq->ith($sqrt);
    my $frac = $period/(2*$sqrt);
    if ($frac > .1) {
      print "$sqrt $period  $frac\n";
    }
  }
  exit 0;
}

{
  # repetitions under gcd

  require Math::PlanePath::GcdRationals;
  sub gcd {
    my $g = shift;
    while (@_) {
      $g = Math::PlanePath::GcdRationals::_gcd($g,shift);
    }
    return $g;
  }

  my %v;
  require Tie::IxHash;
  tie %v, 'Tie::IxHash';

  require Math::NumSeq::SqrtContinued;
  foreach my $sqrt (2 .. 2000) {
    my $seq = Math::NumSeq::SqrtContinued->new (sqrt => $sqrt);
    $seq->next;
    my @values = map{
      my($i,$value)=$seq->next;
      next if ! defined $value;
      $value
    } 1..50;
    my $g = gcd(@values);
    @values = map {$_/$g} @values;
    my $key = join(',',@values);
    ### $key
    push @{$v{$key}}, $sqrt;
  }
  my $uniq = 0;
  foreach my $aref (values %v) {
    if (@$aref > 1) {
      print "repeat: ",join(', ',@$aref),"\n";
    } else {
      $uniq++;
    }
  }
  print "$uniq unique\n";
  exit 0;
}

{
  require Math::NumSeq::SqrtContinuedPeriod;
  my $seq = Math::NumSeq::SqrtContinuedPeriod->new;
  my @periods;
  foreach my $i (2 .. 200) {
    push @periods, $seq->ith($i);
  }
  print "min ",min(@periods),"\n";
  print "max ",max(@periods),"\n";
  exit 0;
}
