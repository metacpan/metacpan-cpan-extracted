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
plan tests => 4;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::Squares;


#------------------------------------------------------------------------------
# A005214 - union triangulars and squares, starting from 1

MyOEIS::compare_values
  (anum => 'A005214',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Triangular;
     my $squares = Math::NumSeq::Squares->new;
     my $triangular = Math::NumSeq::Triangular->new;
     my @got;
     for (my $i = 1; @got < $count; $i++) {
       if ($squares->pred($i) || $triangular->pred($i)) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A000037 - non-squares

MyOEIS::compare_values
  (anum => 'A000037',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Squares->new;
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       if (! $seq->pred($i)) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A010052 - characteristic 1/0 of squares

MyOEIS::compare_values
  (anum => 'A010052',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Squares->new;
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       push @got, $seq->pred($i) ? 1 : 0;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A001105 - 2*n^2

MyOEIS::compare_values
  (anum => 'A001105',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Squares->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, 2*$value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
