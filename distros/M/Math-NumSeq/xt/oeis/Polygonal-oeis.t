#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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

use Math::NumSeq::Polygonal;


#------------------------------------------------------------------------------
# A010052 - characteristic 1/0 of squares

MyOEIS::compare_values
  (anum => 'A010052',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Polygonal->new (polygonal => 4);
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       push @got, $seq->pred($i) ? 1 : 0;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A010054 - characteristic 0/1 of triangular, is also generalized hexagonal

MyOEIS::compare_values
  (anum => 'A010054',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Polygonal->new (polygonal => 3);
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       push @got, $seq->pred($i) ? 1 : 0;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A010054',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::Polygonal->new (polygonal => 6,
                                             pairs => 'both');
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       push @got, $seq->pred($i) ? 1 : 0;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A183221 - the not 9-gonals

MyOEIS::compare_values
  (anum => 'A183221',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::Polygonal->new (polygonal => 9);
     my @got;
     for (my $value = 0; @got < $count; $value++) {
       if (! $seq->pred($value)) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
