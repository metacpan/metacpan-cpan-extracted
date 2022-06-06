#!/usr/bin/perl -w

# Copyright 2012, 2013, 2021, 2022 Kevin Ryde

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
plan tests => 16;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::FibonacciWord;

# uncomment this to run the ### lines
# use Smart::Comments '###';


#------------------------------------------------------------------------------
# cf A178992 - fib word sub-strings which occur, written in decimal

#    0, 1, 2, 3, 5, 6, 10, 11, 13, 21, 22, 26, 27, 43, 45, 53, 54, 86, 90,
# 0 1 10 11
# 101
# 110
# 1010
# 1011
# 1101
# 10101
# 10110
# 11010
# 11011
# 101011
# 101101
# 110110
# 1010110
#     1 0 1 1 0 1 0 1 1 0 1 1 0 1 0 1 1 0 1 0 1 1 0 1

MyOEIS::compare_values
  (anum => 'A178992',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::FibonacciWord->new;
     my @got = (0);
     for (my $len = 1; @got < $count; $len++) {
       my %seen;
       my $seen = 0;
       $seq->rewind;
       my $str = '';
       foreach (1 .. $len) {
         my ($i, $value) = $seq->next;
         $value ^= 1;
         $str .= $value;
       }
       foreach (1 .. 2*$len+10) {
         my $decimal = Math::BigInt->new("0b$str")->bstr;
         if ($str =~ /^1/) {
           $seen{$decimal} = 1;
         }
         my ($i, $value) = $seq->next;
         $value ^= 1;
         $str .= $value;
         $str = substr($str,1,$len);
         ### $value
         ### $str
       }
       foreach my $decimal (sort {$a<=>$b} keys %seen) {
         push @got, $decimal;
         last unless @got < $count;
         ### push: "len=$len decimal=$decimal"
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A089910 - positions of 1,1 in inverse, which is 0,0 in plain

MyOEIS::compare_values
  (anum => 'A089910',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::FibonacciWord->new;
     my @got;
     my $prev = -1;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 0 && $prev == 0) {
         push @got, $i+1;
       }
       $prev = $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A000201 - position of 0s, starting from 1

MyOEIS::compare_values
  (anum => 'A000201',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq  = Math::NumSeq::FibonacciWord->new;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 0) {
         push @got, $i + 1;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A114986 - 1/0 for positions of 0s starting from 1,
# so fib word inverse with extra initial 1

MyOEIS::compare_values
  (anum => 'A114986',
   func => sub {
     my ($count) = @_;
     my @got;
     push @got, 1;
     my $seq  = Math::NumSeq::FibonacciWord->new;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, ($value ? 0 : 1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003622 - position of 1s

MyOEIS::compare_values
  (anum => 'A003622',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq  = Math::NumSeq::FibonacciWord->new;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 1) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A096270 - 0->01, 1->011
# is FibonacciWord invert 1,0 with extra initial 0

MyOEIS::compare_values
  (anum => 'A096270',
   func => sub {
     my ($count) = @_;
     my @got;
     push @got, 0;
     my $seq  = Math::NumSeq::FibonacciWord->new;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, ($value ? 0 : 1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A189479 - 0->01, 1->101
# is FibonacciWord invert 1,0 with extra initial 0,1

MyOEIS::compare_values
  (anum => 'A189479',
   func => sub {
     my ($count) = @_;
     my @got;
     push @got, 0,1;
     my $seq  = Math::NumSeq::FibonacciWord->new;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, ($value ? 0 : 1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A005203 -- bignums of F(n) digits each

MyOEIS::compare_values
  (anum => 'A005203',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my $big = Math::BigInt->new (0);

     require Math::NumSeq::Fibonacci;
     my $fib  = Math::NumSeq::Fibonacci->new;
     $fib->next;
     $fib->next;
     my ($target_i, $target) = $fib->next;

     my @got = (0);
     my $seq  = Math::NumSeq::FibonacciWord->new;
     while (@got < $count) {
       my ($i, $value) = $seq->next;

       if ($i >= $target) {
         push @got, $big;
         ($target_i, $target) = $fib->next;
       }

       $value = 1 - $value;
       $big = 2*$big + $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A008352 -- decimal bignums low to high, 1,2

MyOEIS::compare_values
  (anum => 'A008352',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my $big = Math::BigInt->new(0);

     require Math::NumSeq::Fibonacci;
     my $fib  = Math::NumSeq::Fibonacci->new;
     $fib->next;
     $fib->next;
     my ($target_i, $target) = $fib->next;

     my @got = (1);
     my $seq  = Math::NumSeq::FibonacciWord->new;
     my $pow = Math::BigInt->new(1);
     while (@got < $count) {
       my ($i, $value) = $seq->next;

       if ($i >= $target) {
         push @got, $big;
         ($target_i, $target) = $fib->next;
       }

       $big += $pow * ($value ? 1 : 2);
       $pow *= 10;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A005614 - 1,0

MyOEIS::compare_values
  (anum => 'A005614',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::FibonacciWord->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $value = 1 - $value;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003842 - 1,2

MyOEIS::compare_values
  (anum => 'A003842',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::FibonacciWord->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, ($value ? 2 : 1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A014675 - 2,1

MyOEIS::compare_values
  (anum => 'A014675',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::FibonacciWord->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, ($value ? 1 : 2);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A001468 - 1,2 extra initial 1

MyOEIS::compare_values
  (anum => 'A001468',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $seq  = Math::NumSeq::FibonacciWord->new;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, ($value ? 1 : 2);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A076662 - first diffs of positions of 0s, is 2,3 with extra initial 3

MyOEIS::compare_values
  (anum => 'A076662',
   func => sub {
     my ($count) = @_;
     my @got = (3);
     my $seq  = Math::NumSeq::FibonacciWord->new;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, ($value ? 2 : 3);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A143667 - dense Fibonacci word

MyOEIS::compare_values
  (anum => 'A143667',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::FibonacciWord->new;
     my @got;
     while (@got < $count) {
       my ($i1, $value1) = $seq->next;
       my ($i2, $value2) = $seq->next;
       push @got, 2*$value1 + $value2;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A036299 -- binary bignums high to low, inverted 1,0

MyOEIS::compare_values
  (anum => 'A036299',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my $big = Math::BigInt->new (0);

     require Math::NumSeq::Fibonacci;
     my $fib  = Math::NumSeq::Fibonacci->new;
     $fib->next;
     $fib->next;
     my ($target_i, $target) = $fib->next;

     my $seq  = Math::NumSeq::FibonacciWord->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;

       if ($i >= $target) {
         push @got, $big;
         ($target_i, $target) = $fib->next;
       }

       $big *= 10;
       $big += ($value ? 0 : 1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
