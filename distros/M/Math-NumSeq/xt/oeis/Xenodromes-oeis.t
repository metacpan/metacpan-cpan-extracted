#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014 Kevin Ryde

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
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::Xenodromes;

# uncomment this to run the ### lines
# use Smart::Comments;


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
# A036918 number of xenodromes in radix n

MyOEIS::compare_values
  (anum => 'A036918',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $radix = 2; @got < $count; $radix++) {
       my $seq = Math::NumSeq::Xenodromes->new (radix => $radix);
       push @got, numseq_probe_i_end($seq);
     }
     return \@got;
   });

sub numseq_probe_i_end {
  my ($seq) = @_;
  my $lo = $seq->i_start;
  $lo = Math::NumSeq::_to_bigint($lo);
  my $hi = $lo + 1;
  while (defined($seq->ith($hi))) {
    $hi *= 2;
  }
  for (;;) {
    my $mid = ($hi + $lo) / 2;
    if ($mid == $lo) {
      return $mid;
    }
    if (defined $seq->ith($mid)) {
      $lo = $mid;
    } else {
      $hi = $mid;
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
