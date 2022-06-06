#!/usr/bin/perl -w

# Copyright 2012, 2020 Kevin Ryde

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
plan tests => 5;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::GolombSequence;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A104236 n*golomb(n)

MyOEIS::compare_values
  (anum => 'A104236',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::GolombSequence->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $i * $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A143125 n*golomb(n) cumulative

MyOEIS::compare_values
  (anum => 'A143125',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::GolombSequence->new;
     my $cumulative = 0;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $cumulative += $i * $value;
       push @got, $cumulative;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A088517 increments

MyOEIS::compare_values
  (anum => 'A088517',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::GolombSequence->new;
     my ($i, $prev) = $seq->next;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value - $prev;
       $prev = $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A001463 partial sums

MyOEIS::compare_values
  (anum => 'A001463',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::GolombSequence->new;
     my @got;
     my $cumulative = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $cumulative += $value;
       push @got, $cumulative;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A095114 partial sums + 1

MyOEIS::compare_values
  (anum => 'A095114',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::GolombSequence->new;
     my @got = (1);
     my $cumulative = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $cumulative += $value;
       push @got, $cumulative + 1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
