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
plan tests => 18;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::LuckyNumbers;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A031162 - lucky and square

MyOEIS::compare_values
  (anum => 'A031162',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Squares;
     my $lucky = Math::NumSeq::LuckyNumbers->new;
     my $square = Math::NumSeq::Squares->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $lucky->next;
       if ($square->pred($value)) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A137164 etc - Lucky with various modulo

foreach my $elem (['A137164', 0, 3],
                  ['A137165', 1, 3],

                  ['A137168', 1, 4],
                  ['A137170', 3, 4],

                  ['A137182', 0, 7],
                  ['A137183', 1, 7],
                  ['A137184', 2, 7],
                  ['A137185', 3, 7],
                  ['A137186', 4, 7],
                  ['A137187', 5, 7],
                  ['A137188', 6, 7],

                  ['A137190', 1, 8],
                  ['A137192', 3, 8],
                  ['A137194', 5, 8],
                  ['A137196', 7, 8],
                 ) {
  my ($anum, $target, $modulus) = @$elem;

  MyOEIS::compare_values
      (name => "$anum - lucky congruent to $target modulo $modulus",
       anum => $anum,
       max_value => 1_000_000,
       func => sub {
         my ($count) = @_;
         my $seq = Math::NumSeq::LuckyNumbers->new;
         my @got;

         while (@got < $count) {
           my ($i, $value) = $seq->next;
           if (($value % $modulus) == $target) {
             push @got, $value;
           }
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A118567 - Lucky with only odd digits

MyOEIS::compare_values
  (anum => 'A118567',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::LuckyNumbers->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value =~ /^[13579]+$/) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A050505 - non-Lucky numbers

MyOEIS::compare_values
  (anum => 'A050505',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::LuckyNumbers->new;
     my @got;
     my ($i, $value) = $seq->next;
     for (my $n = 1; @got < $count; $n++) {
       if ($n < $value) {
         push @got, $n;
       } else {
         ($i, $value) = $seq->next;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A145649 - 0,1 characteristic

MyOEIS::compare_values
  (anum => 'A145649',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::LuckyNumbers->new;
     my @got;
     my ($i, $value) = $seq->next;
     for (my $n = 1; @got < $count; $n++) {
       if ($n < $value) {
         push @got, 0;
       } else {
         push @got, 1;
         ($i, $value) = $seq->next;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
