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
plan tests => 2;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::Tetrahedral;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A100679 floor(cbrt(tetrahedral))

MyOEIS::compare_values
  (anum => 'A100679',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my $seq = Math::NumSeq::Tetrahedral->new;
     my @got;
     for (my $i = Math::BigInt->new(0); @got < $count; $i++) {
       my $value = $seq->ith($i);
       $value->broot(3);
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A027568 triangular and tetrahedral

MyOEIS::compare_values
  (anum => 'A027568',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Triangular;
     my $tr = Math::NumSeq::Triangular->new;
     my $seq = Math::NumSeq::Tetrahedral->new;
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($tr->pred($value)) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A004161 tetrahedrals written backwards

MyOEIS::compare_values
  (anum => 'A004161',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Tetrahedral->new (i_start => 1);
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, reverse($value)+0;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003556 square and tetrahedral

MyOEIS::compare_values
  (anum => 'A003556',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Squares;
     my $sq = Math::NumSeq::Squares->new;
     my $seq = Math::NumSeq::Tetrahedral->new;
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($sq->pred($value)) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A193108 tetrahedrals mod 10

MyOEIS::compare_values
  (anum => 'A193108',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Tetrahedral->new (i_start => 1);
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value % 10;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A162904 - tetrahedral-2 is a prime

MyOEIS::compare_values
  (anum => 'A162904',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $pr = Math::NumSeq::Primes->new;
     my $seq = Math::NumSeq::Tetrahedral->new;
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($pr->pred($value-2)) {
         push @got, $value-2;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A145397 non-tetrahedrals

MyOEIS::compare_values
  (anum => 'A145397',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Tetrahedral->new;
     my @got;
     for (my $value = 0; @got < $count; $value++) {
       if (! $seq->pred($value)) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A140236 double-tetrahedrals

MyOEIS::compare_values
  (anum => 'A140236',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Tetrahedral->new;
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $seq->ith($value);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
