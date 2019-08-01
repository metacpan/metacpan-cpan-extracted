#!/usr/bin/perl -w

# Copyright 2012, 2013, 2019 Kevin Ryde

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

use Math::NumSeq::Triangular;

# uncomment this to run the ### lines
#use Smart::Comments '###';

#------------------------------------------------------------------------------
# A190660 - count triangulars 2^(n-1) < T <= 2^k
# start n=0 2^-1=1/2 < T <= 2^0=1 is T=1 only

MyOEIS::compare_values
  (anum => 'A190660',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Triangular->new;
     my @got = (1);
     for (my $pow = 1; @got < $count; $pow *= 2) {
       push @got, ($seq->value_to_i_floor(2*$pow)
                   - $seq->value_to_i_floor($pow));
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A010054 - characteristic 0/1 of triangular

MyOEIS::compare_values
  (anum => 'A010054',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Triangular->new;
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       push @got, $seq->pred($i) ? 1 : 0;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
