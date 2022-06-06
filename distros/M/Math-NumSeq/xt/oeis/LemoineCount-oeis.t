#!/usr/bin/perl -w

# Copyright 2012, 2020 Kevin Ryde

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

use Math::NumSeq::LemoineCount;


#------------------------------------------------------------------------------
# A194830 - odd record positions

MyOEIS::compare_values
  (anum => 'A194830',
   max_count => 60,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::LemoineCount->new;
     my @got;
     my $record = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if (($i&1) && $value > $record) {
         $record = $value;
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A194831 - odd record values

MyOEIS::compare_values
  (anum => 'A194831',
   max_count => 60,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::LemoineCount->new;
     my @got;
     my $record = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if (($i&1) && $value > $record) {
         $record = $value;
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
