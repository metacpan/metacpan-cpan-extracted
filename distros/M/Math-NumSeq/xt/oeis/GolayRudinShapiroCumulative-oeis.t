#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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

use Math::NumSeq::GolayRudinShapiroCumulative;

# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------
# A212591 - position of first occurance of n

MyOEIS::compare_values
  (anum => 'A212591',
   max_count => 1000,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::GolayRudinShapiroCumulative->new;
     my @got;
     my $target = 1;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == $target) {
         push @got, $i;
         $target++;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A020991 - position of last occurrence of k in the partial sums

MyOEIS::compare_values
  (anum => 'A020991',
   max_count => 1000,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::GolayRudinShapiroCumulative->new;
     my @got;
     my @reps;
     for (my $n = 1; @got < $count; ) {
       my ($i, $value) = $seq->next;
       $reps[$value]++;
       if ($value == $n && $reps[$value] >= $n) {  # last
         push @got, $i;
         $n++;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A051032 - GRS cumulative of 2^n

MyOEIS::compare_values
  (anum => 'A051032',
   max_count => 1000,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::GolayRudinShapiroCumulative->new;
     require Math::BigInt;
     my @got;
     for (my $n = Math::BigInt->new(1); @got < $count; $n *= 2) {
       push @got, $seq->ith($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A022156 - first differences of A020991 highest occurrence of n in cumulative

MyOEIS::compare_values
  (anum => 'A022156',
   max_count => 1000,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::GolayRudinShapiroCumulative->new;
     my @got;
     my @reps;
     my $prev = 0;
     for (my $n = 1; @got < $count; ) {
       my ($i, $value) = $seq->next;
       $reps[$value]++;
       if ($value == $n && $reps[$value] >= $n) {
         if ($n >= 2) {
           push @got, $i - $prev;
         }
         $prev = $i;
         $n++;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A093573 - triangle of n as cumulative

MyOEIS::compare_values
  (anum => 'A093573',
   max_count => 1000,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::GolayRudinShapiroCumulative->new;
     my @got;
     my @triangle;
     for (my $n = 1; @got < $count; ) {
       my ($i, $value) = $seq->next;

       my $aref = ($triangle[$value] ||= []);
       push @$aref, $i;
       if ($value == $n && scalar(@$aref) == $n) {
         while (@$aref && @got < $count) {
           push @got, shift @$aref;
         }
         delete $triangle[$value];
         $n++;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
