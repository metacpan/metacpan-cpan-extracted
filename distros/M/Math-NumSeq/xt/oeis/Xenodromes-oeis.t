#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2019 Kevin Ryde

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
use Math::BigInt try => 'GMP';
use Test;
plan tests => 5;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::Xenodromes;

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------
# A036918 number of xenodromes in radix n

MyOEIS::compare_values
  (anum => 'A036918',
   max_value => 10000,
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $radix = 2; @got < $count; $radix++) {
       my $seq = Math::NumSeq::Xenodromes->new (radix => $radix);
       my $i_start = $seq->i_start;
       my $i_end = numseq_probe_i_end($seq);
       ### i_start: "$i_start"
       ### i_end  : "$i_end"

       # how many values inclusive, but excluding value 0
       push @got, $i_end - $i_start;
     }
     return \@got;
   });

# Return the biggest i with a value in $seq.
# ENHANCE-ME: Some method or property on the seq for i_end.
sub numseq_probe_i_end {
  my ($seq) = @_;
  my $lo = $seq->i_start;
  unless (defined($seq->ith($lo))) {
    return undef; # empty sequence
  }
  $lo = Math::BigInt->new($lo);
  my $hi = $lo + 1;
  while (defined($seq->ith($hi))) {
    $hi *= 2;
  }
  for (;;) {
    ### at: "$lo to $hi"
    ### lo val: $seq->ith($lo).""
    ### hi val: $seq->ith($hi).""
    my $mid = ($lo + $hi) >> 1;
    if ($mid == $lo) {
      last;
    }
    if (defined $seq->ith($mid)) {
      $lo = $mid;
    } else {
      $hi = $mid;
    }
  }

  (defined $seq->ith($lo) && ! defined $seq->ith($lo+1))
    or die "oops";
  return $lo;
}

#------------------------------------------------------------------------------
# A178787 count xenodromes up to n

MyOEIS::compare_values
  (anum => 'A178787',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Xenodromes->new;
     my @got;
     my $total = 0;
     for (my $value = 0; @got < $count; $value++) {
       if ($seq->pred($value)) {
         $total++;
       }
       push @got, $total;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A029743 primes with distinct digits

MyOEIS::compare_values
  (anum => 'A029743',
   max_value => 1_000_000,
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $primes = Math::NumSeq::Primes->new;
     my $seq = Math::NumSeq::Xenodromes->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $primes->next;
       if ($seq->pred($value)) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A178788 xenodromes characteristic 0,1

MyOEIS::compare_values
  (anum => 'A178788',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Xenodromes->new;
     my @got;
     for (my $value = 0; @got < $count; $value++) {
       push @got, $seq->pred($value) ? 1 : 0;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A109303 non-xenodromes

MyOEIS::compare_values
  (anum => 'A109303',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Xenodromes->new;
     my @got;
     for (my $value = 0; @got < $count; $value++) {
       if (! $seq->pred($value)) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
