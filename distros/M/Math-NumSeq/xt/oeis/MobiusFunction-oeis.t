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

use Math::NumSeq::MobiusFunction;


#------------------------------------------------------------------------------
# A063838 mu(n) + mu(n+1) + mu(n+2) = 3      # run three 1s
# A070268 mu(n) + mu(n+1) + mu(n+2) = -3     # run three -1s
# A063848 mu(n) + mu(n+1) + mu(n+2) = 2
# A063849 mu(n) + mu(n+1) + mu(n+2) = 1

MyOEIS::compare_values
  (anum => 'A070268',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::MobiusFunction->new;
     my @got;
     for (my $i = 1; @got < $count; $i++) {
       if ($seq->ith($i) + $seq->ith($i+1) + $seq->ith($i+2) == -3) {
         push @got, $i;
       }
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A063838',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::MobiusFunction->new;
     my @got;
     for (my $i = 1; @got < $count; $i++) {
       if ($seq->ith($i) + $seq->ith($i+1) + $seq->ith($i+2) == 3) {
         push @got, $i;
       }
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A063848',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::MobiusFunction->new;
     my @got;
     for (my $i = 1; @got < $count; $i++) {
       if ($seq->ith($i) + $seq->ith($i+1) + $seq->ith($i+2) == 2) {
         push @got, $i;
       }
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A063849',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::MobiusFunction->new;
     my @got;
     for (my $i = 1; @got < $count; $i++) {
       if ($seq->ith($i) + $seq->ith($i+1) + $seq->ith($i+2) == 1) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A064148 mu(n) = mu(n+1)
# A074819 mu(n) = - mu(n+1)

MyOEIS::compare_values
  (anum => 'A064148',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::MobiusFunction->new;
     my @got;
     for (my $i = 1; @got < $count; $i++) {
       if ($seq->ith($i) == $seq->ith($i+1)) {
         push @got, $i;
       }
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A074819',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::MobiusFunction->new;
     my @got;
     for (my $i = 1; @got < $count; $i++) {
       if ($seq->ith($i) == - $seq->ith($i+1)) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A074820 - mu(n)=mu(n+2)

MyOEIS::compare_values
  (anum => 'A074820',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::MobiusFunction->new;
     my @got;
     for (my $i = 1; @got < $count; $i++) {
       if ($seq->ith($i) == $seq->ith($i+2)) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
