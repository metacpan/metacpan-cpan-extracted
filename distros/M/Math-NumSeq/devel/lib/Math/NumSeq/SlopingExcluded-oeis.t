#!/usr/bin/perl -w

# Copyright 2012, 2014 Kevin Ryde

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

use lib 't','xt',              'devel/lib';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::SlopingExcluded;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A109684 - sloping ternary excluded, in ternary

MyOEIS::compare_values
  (anum => 'A109684',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::SlopingExcluded->new (radix => 3);
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, to_ternary_str($value);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A103202 - sloping binary numbers, ie. the included values
# cf A102370 unsorted

MyOEIS::compare_values
  (anum => 'A103202',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::SlopingExcluded->new;
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       if (! $seq->pred($i)) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A103581 - sloping binary excluded, in binary

MyOEIS::compare_values
  (anum => 'A103581',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::SlopingExcluded->new (radix => 2);
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, to_binary_str($value);
     }
     return \@got;
   });

sub to_binary_str {
  my ($n) = @_;
  if (ref $n) {
    my $str = $n->as_bin;
    $str =~ s/^0b//;
    return $str;
  }
  if ($n == 0) { return '0'; }
  my $str = '';
  my @bits;
  while ($n) {
    push @bits, $n%2;
    $n = int($n/2);
  }
  return join('',reverse @bits);
}

sub to_ternary_str {
  my ($n) = @_;
  if ($n == 0) { return '0'; }
  my $str = '';
  my @digits;
  while ($n) {
    my $digit = $n % 3;
    push @digits, $digit;
    $n = int(($n-$digit)/3);
  }
  return join('',reverse @digits);
}

#------------------------------------------------------------------------------
exit 0;
