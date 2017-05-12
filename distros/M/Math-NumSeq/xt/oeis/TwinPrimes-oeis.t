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
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::TwinPrimes;

# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------
# A100923 - characteristic boolean 0 or 1 according as 6n+/-1 both prime

MyOEIS::compare_values
  (anum => 'A100923',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::TwinPrimes->new (pairs => 'first');
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       if ($seq->pred(6*$n-1)) {
         push @got, 1;
       } else {
         push @got, 0;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
