#!/usr/bin/perl -w

# Copyright 2012, 2014, 2019, 2020 Kevin Ryde

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
plan tests => 17;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::Palindromes;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A057148 binary palindromes written in binary
MyOEIS::compare_values
  (anum => 'A057148',
   func => sub {
     my ($count) = @_;
     require Math::BaseCnv;
     my $seq = Math::NumSeq::Palindromes->new (radix => 2);
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, Math::BaseCnv::cnv($value,10,2);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A118595 base-4 palindromes written in base-4
MyOEIS::compare_values
  (anum => 'A118595',
   func => sub {
     my ($count) = @_;
     require Math::BaseCnv;
     my $seq = Math::NumSeq::Palindromes->new (radix => 4);
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, Math::BaseCnv::cnv($value,10,4);
     }
     return \@got;
   });

# A048703 base-4 palindromes even length
MyOEIS::compare_values
  (anum => 'A048703',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::DigitLength;
     my $seq = Math::NumSeq::Palindromes->new (radix => 4);
     my $len = Math::NumSeq::DigitLength->new (radix => 4);
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 0 || $len->ith($value) % 2 == 0) {
         push @got, $value;
       }
     }
     return \@got;
   });

# A048704 base-4 palindromes even length divide 5
MyOEIS::compare_values
  (anum => 'A048704',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::DigitLength;
     my $seq = Math::NumSeq::Palindromes->new (radix => 4);
     my $len = Math::NumSeq::DigitLength->new (radix => 4);
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 0 || $len->ith($value) % 2 == 0) {
         push @got, $value / 5;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A206919 sum binary palindromes <= n

MyOEIS::compare_values
  (anum => 'A206919',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Palindromes->new (radix => 2);
     my $total = 0;
     my @got;
     my ($i, $value) = $seq->next;
     for (my $n = 0; @got < $count; $n++) {
       if ($value <= $n) {
         $total += $value;
         ($i, $value) = $seq->next;
       }
       push @got, $total;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A206920 cumulative binary palindromes, sum first n binary palindromes

MyOEIS::compare_values
  (anum => 'A206920',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Palindromes->new (radix => 2);
     my $total = 0;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $total += $value;
       push @got, $total;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A048700 binary palindromes odd length
MyOEIS::compare_values
  (anum => 'A048700',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::DigitLength;
     my $seq = Math::NumSeq::Palindromes->new (radix => 2);
     my $len = Math::NumSeq::DigitLength->new (radix => 2);
     $seq->next; # not 0
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($len->ith($value) % 2 == 1) {
         push @got, $value;
       }
     }
     return \@got;
   });

# A048701 binary palindromes even length, including 0 as no digits
MyOEIS::compare_values
  (anum => 'A048701',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::DigitLength;
     my $seq = Math::NumSeq::Palindromes->new (radix => 2);
     my $len = Math::NumSeq::DigitLength->new (radix => 2);
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 0 || $len->ith($value) % 2 == 0) {
         push @got, $value;
       }
     }
     return \@got;
   });
# A048702 binary palindromes even length divide 3
MyOEIS::compare_values
  (anum => 'A048702',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::DigitLength;
     my $seq = Math::NumSeq::Palindromes->new (radix => 2);
     my $len = Math::NumSeq::DigitLength->new (radix => 2);
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 0 || $len->ith($value) % 2 == 0) {
         push @got, $value/3;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A029735 - cubes are hex palindromes

MyOEIS::compare_values
  (anum => 'A029735',
   max_value => 10000,
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Cubes;
     my $cubeseq = Math::NumSeq::Cubes->new;
     my $palseq = Math::NumSeq::Palindromes->new (radix => 16);
     my @got;
     while (@got < $count) {
       my ($i, $value) = $cubeseq->next;
       if ($palseq->pred($value)) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A029736 - hex palindrome cubes

MyOEIS::compare_values
  (anum => 'A029736',
   max_value => 10000**3,
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Cubes;
     my $cubeseq = Math::NumSeq::Cubes->new;
     my $palseq = Math::NumSeq::Palindromes->new (radix => 16);
     my @got;
     while (@got < $count) {
       my ($i, $value) = $cubeseq->next;
       if ($palseq->pred($value)) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A029731 - palindromes in both decimal and hexadecimal

MyOEIS::compare_values
  (anum => 'A029731',
   func => sub {
     my ($count) = @_;
     my $dec = Math::NumSeq::Palindromes->new;
     my $hex = Math::NumSeq::Palindromes->new (radix => 16);
     my @got;
     while (@got < $count) {
       my ($i, $value) = $dec->next;
       if ($hex->pred($value)) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A029733 - squares are hex palindromes

MyOEIS::compare_values
  (anum => 'A029733',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Palindromes->new (radix => 16);
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       if ($seq->pred($n*$n)) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A029734 - hex palindrome squares

MyOEIS::compare_values
  (anum => 'A029734',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Palindromes->new (radix => 16);
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $square = $n*$n;
       if ($seq->pred($square)) {
         push @got, $square;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A137180 count of palindromes 1 to n

MyOEIS::compare_values
  (anum => 'A137180',
   func => sub {
     my ($count) = @_;
     my $palindromes = Math::NumSeq::Palindromes->new;
     my @got = (0); # starting n=0 not considered a palindrome
     my $num_palindromes = 0;
     for (my $n = 1; @got < $count; $n++) {
       $num_palindromes++ if $palindromes->pred($n);
       push @got, $num_palindromes;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A002385 Palindromes primes, decimal

MyOEIS::compare_values
  (anum => 'A002385',
   max_value => 0xFFFF_FFFF,
   func => sub {
     my ($count) = @_;
     my $palindromes = Math::NumSeq::Palindromes->new;
     require Math::NumSeq::Primes;
     my $primes  = Math::NumSeq::Primes->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $palindromes->next;
       ### $i
       ### $value
       my $is_prime = $primes->pred($value);
       if (! defined $is_prime) {
         MyTestHelpers::diag ("  too big at i=$i, value=$value");
         last;
       }
       if ($is_prime) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A029732 Palindromes primes, hexadecimal

MyOEIS::compare_values
  (anum => 'A029732',
   max_value => 0xFFFF_FFFF,
   func => sub {
     my ($count) = @_;
     my $palindromes = Math::NumSeq::Palindromes->new (radix => 16);
     require Math::NumSeq::Primes;
     my $primes  = Math::NumSeq::Primes->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $palindromes->next;
       ### $i
       ### $value
       my $is_prime = $primes->pred($value);
       if (! defined $is_prime) {
         MyTestHelpers::diag ("  too big at i=$i, value=$value");
         last;
       }
       if ($is_prime) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
