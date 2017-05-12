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
plan tests => 3;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::WoodallNumbers;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A050918 Woodall primes

MyOEIS::compare_values
  (anum => 'A050918',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $primes  = Math::NumSeq::Primes->new;
     my $woodall = Math::NumSeq::WoodallNumbers->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $woodall->next;
       ### $i
       ### $value
       my $is_prime = $primes->pred($value);
       if (! defined $is_prime) {
         last; # too big
       }
       if ($is_prime) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A002234 Woodall primes, the n value

MyOEIS::compare_values
  (anum => 'A002234',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $primes  = Math::NumSeq::Primes->new;
     my $woodall = Math::NumSeq::WoodallNumbers->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $woodall->next;
       ### $i
       ### $value
       my $is_prime = $primes->pred($value);
       if (! defined $is_prime) {
         last; # too big
       }
       if ($is_prime) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A056821 totient(Woodall)

MyOEIS::compare_values
  (anum => 'A056821',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Totient;
     my $totient = Math::NumSeq::Totient->new;
     my $woodall = Math::NumSeq::WoodallNumbers->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $woodall->next;
       push @got, $totient->ith($value);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
