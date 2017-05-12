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

use Math::NumSeq::PowerFlip;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A005117 - squarefrees all-and-only value 1

MyOEIS::compare_values
  (anum => 'A005117',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PowerFlip->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 1) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A013929 - non-squarefrees all-and-only value!=1

MyOEIS::compare_values
  (anum => 'A013929',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PowerFlip->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value != 1) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------

exit 0;
