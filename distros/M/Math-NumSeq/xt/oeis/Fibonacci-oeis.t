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
plan tests => 11;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::Fibonacci;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A014445 = F(3n)
# A033887 = F(3n+1)
# A015448 = F(3n-1),

MyOEIS::compare_values
  (anum => 'A015448',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq  = Math::NumSeq::Fibonacci->new;
     for (my $n = Math::BigInt->new(0); @got < $count; $n++) {
       push @got, $seq->ith(3*$n-1);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A033887',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq  = Math::NumSeq::Fibonacci->new;
     for (my $n = Math::BigInt->new(0); @got < $count; $n++) {
       push @got, $seq->ith(3*$n+1);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A014445',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq  = Math::NumSeq::Fibonacci->new;
     for (my $n = Math::BigInt->new(0); @got < $count; $n++) {
       push @got, $seq->ith(3*$n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A039834 - Fibonacci negative indices F[-n] starting F[0] then downwards

MyOEIS::compare_values
  (anum => 'A039834',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Fibonacci->new;
     my @got;
     for (my $i = Math::BigInt->new(0); @got < $count; $i--) {
       push @got, $seq->ith($i);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A087172 - next lower Fibonacci <= n

MyOEIS::compare_values
  (anum => 'A087172',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Fibonacci->new;
     my @got;
     $seq->next; # skip 0
     (undef, my $fib) = $seq->next;
     (undef, my $next_fib) = $seq->next;
     for (my $n = 2; @got < $count; $n++) {
       while ($next_fib < $n) {
         $fib = $next_fib;
         (undef, $next_fib) = $seq->next;
       }
       push @got, $fib;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A005592 - F(2n+1)+F(2n-1)-1

MyOEIS::compare_values
  (anum => 'A005592',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq  = Math::NumSeq::Fibonacci->new;
     for (my $n = Math::BigInt->new(1); @got < $count; $n++) {
       push @got, $seq->ith(2*$n+1) + $seq->ith(2*$n-1) - 1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A108852 - num fibs <= n

MyOEIS::compare_values
  (anum => 'A108852',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq  = Math::NumSeq::Fibonacci->new;
     push @got, 1;   # past 1 occurring twice
     my $num = 3;
     for (my $n = 2; @got < $count; $n++) {
       push @got, $num;
       if ($seq->pred($n)) {
         $num++;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A035105 - LCM of fibs

MyOEIS::compare_values
  (anum => 'A035105',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq  = Math::NumSeq::Fibonacci->new;
     $seq->next; # skip 0
     my $lcm = Math::BigInt->new(1);
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $lcm = lcm($lcm,$value);
       push @got, $lcm;
     }
     return \@got;
   });

sub lcm {
  my $ret = shift;
  while (@_) {
    my $value = shift;
    my $gcd = Math::BigInt::bgcd($ret,$value);
    $ret *= $value/$gcd;
  }
  return $ret;
}

#------------------------------------------------------------------------------
# A020909 - length in bits of F[n]

MyOEIS::compare_values
  (anum => 'A020909',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     require Math::NumSeq::DigitLength;
     my $len  = Math::NumSeq::DigitLength->new(radix=>2);
     my $seq  = Math::NumSeq::Fibonacci->new;
     $seq->next; # skip initial 0
     my @got;
     while (@got < $count) {
       my ($i, $fib) = $seq->next;
       push @got, $len->ith($fib);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A060384 - number of decimal digits in Fib[n]

MyOEIS::compare_values
  (anum => 'A060384',
   max_count => 200,     # full b-file a bit slow
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::DigitLength;
     my $cnt = Math::NumSeq::DigitLength->new;
     my $seq = Math::NumSeq::Fibonacci->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $cnt->ith($value);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A114477 smallest Fibonacci with n 1-bits, or -1 if no such

MyOEIS::compare_values
  (anum => 'A114477',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::DigitCount;
     my $cnt = Math::NumSeq::DigitCount->new(radix=>2);
     my $seq = Math::NumSeq::Fibonacci->new;
     my @got = (0);
     my $got_count = 0;
     while ($got_count < $count) {
       my ($i, $value) = $seq->next;
       my $c = $cnt->ith($value);
       if ($c < $count && ! $got[$c]) {
         $got_count++;
         $got[$c] = $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
