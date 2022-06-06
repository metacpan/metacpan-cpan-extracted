#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2019, 2021 Kevin Ryde

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
use List::Util 'min','max';
use Test;
plan tests => 4;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::FibonacciRepresentations;

# uncomment this to run the ### lines
# use Smart::Comments '###';


#------------------------------------------------------------------------------
# A303903 - R increments

MyOEIS::compare_values
  (anum => 'A303903',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::FibonacciRepresentations->new;
     my @got = (1);
     for (my $n = 0; @got < $count; $n++) {
       push @got, $seq->ith($n+1) - $seq->ith($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A000121 - R cumulative

MyOEIS::compare_values
  (anum => 'A000119',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::FibonacciRepresentations->new;
     my @got;
     my $total = -1;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $total += $value;
       push @got, $total;
     }
     return \@got;
   });



#------------------------------------------------------------------------------
# A000121 - R'(n), allowing Fib 1 twice

MyOEIS::compare_values
  (anum => 'A000121',
   # max_value => 2000000,
   func => sub {
     my ($count) = @_;
     my @got;
     my @seen;
     my $seq = Math::NumSeq::FibonacciRepresentations->new;
     my $prev = 0;
     for (my $n = 1; @got < $count; $n++) {
       my ($i, $value) = $seq->next;
       push @got, $value + $prev;
       $prev = $value;
     }
     $got[0] = 1;
     return \@got;
   });


#------------------------------------------------------------------------------
# A046815 - smallest x for which R(x) = n and x uses only even Fibs

MyOEIS::compare_values
  (anum => 'A046815',
   # max_value => 2000000,
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Fibbinary;
     my $fibbinary = Math::NumSeq::Fibbinary->new;
     my $seq = Math::NumSeq::FibonacciRepresentations->new;
     my @got;
     my @seen;
     for (my $n = 1; @got < $count; $n++) {
       while (! defined $seen[$n]) {
         my ($i, $value) = $seq->next;
         if ($value <= $count
             && ! defined $seen[$value]
             && all_odds_0($fibbinary->ith($i))) {
           ### seen: "$value at i=$i"
           $seen[$value] = $i;
         }
       }
       push @got, $seen[$n];
     }
     $got[0] = 1;
     return \@got;
   });

sub all_odds_0 {
  my ($n) = @_;
  while ($n) {
    if ($n & 2) { return 0; }
    $n >>= 2;
  }
  return 1;
}

#------------------------------------------------------------------------------
# A083853 - smallest x for which R'(x) = n
# R'(x) counts 1 twice, which is R'(x) = R(x)+R(x-1)

MyOEIS::compare_values
  (anum => 'A083853',
   func => sub {
     my ($count) = @_;
     my @got;
     my @seen;
     my $prev = 0;
     my $seq = Math::NumSeq::FibonacciRepresentations->new;
     for (my $n = 1; @got < $count; $n++) {
       while (! defined $seen[$n]) {
         my ($i, $this) = $seq->next;
         my $value = $this + $prev;
         $prev = $this;
         if ($value <= $count && ! defined $seen[$value]) {
           ### seen: "$value at i=$i"
           $seen[$value] = $i;
         }
       }
       push @got, $seen[$n];
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A013583 - smallest x for which R(x) = n

MyOEIS::compare_values
  (anum => 'A013583',
   max_value => 200000,
   func => sub {
     my ($count) = @_;
     my @got;
     my @seen;
     my $seq = Math::NumSeq::FibonacciRepresentations->new;
     for (my $n = 1; @got < $count; $n++) {
       while (! defined $seen[$n]) {
         my ($i, $value) = $seq->next;
         if ($value <= $count && ! defined $seen[$value]) {
           ### seen: "$value at i=$i"
           $seen[$value] = $i;
         }
       }
       push @got, $seen[$n];
     }
     $got[0] = 1;
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
