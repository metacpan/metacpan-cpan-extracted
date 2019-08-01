#!/usr/bin/perl -w

# Copyright 2014, 2019 Kevin Ryde

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
use Math::BigInt;
use Test;
plan tests => 4;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::Pell;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A052208 something Pell(n)*Pell(2*n)/2.

MyOEIS::compare_values
  (anum => 'A052208',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Pell->new;
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       push @got, Math::BigInt->new($seq->ith($i)) * $seq->ith(2*$i) / 2;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A077985 negatives P[-1-n]
# offset=0 value=1, whereas P[0]=0 then P[-1]=1

MyOEIS::compare_values
  (anum => 'A077985',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Pell->new;
     my @got;
     for (my $i = -1; @got < $count; $i--) {
       push @got, $seq->ith($i);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A001333 cont frac numerators, being P[n]+P[n-1]

MyOEIS::compare_values
  (anum => 'A001333',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Pell->new;
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       push @got, $seq->ith($i) + $seq->ith($i-1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A048739 Pell cumulative

MyOEIS::compare_values
  (anum => 'A048739',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Pell->new;
     my @got;
     $seq->next;  # starting at value=1
     for (my $value = 0; @got < $count; $value++) {
       my ($i,$value) = $seq->next;
       push @got, ($got[-1]||0) + $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
