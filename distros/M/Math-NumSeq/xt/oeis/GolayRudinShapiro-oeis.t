#!/usr/bin/perl -w

# Copyright 2012, 2013, 2019, 2020 Kevin Ryde

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
plan tests => 12;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::GolayRudinShapiro;


#------------------------------------------------------------------------------
# A203531 GRS run lengths

MyOEIS::compare_values
  (anum => 'A203531',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::GolayRudinShapiro->new;
     my @got;
     (undef, my $prev) = $seq->next;
     my $runlength = 1;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == $prev) {
         $runlength++;
       } else {
         push @got, $runlength;
         $prev = $value;
         $runlength = 1;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A014081 - count of 11 bit pairs, taken mod 2 is GRS

MyOEIS::compare_values
  (anum => 'A014081',
   fixup => sub {         # mangle to mod 2
     my ($aref) = @_;
     foreach (@$aref) { $_ %= 2; }
   },
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::GolayRudinShapiro->new (values_type => '0,1');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A005943 - number of subwords length n

MyOEIS::compare_values
  (anum => 'A005943',
   max_count => 14,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::GolayRudinShapiro->new (values_type => '0,1');
     my @got;
     for (my $len = 1; @got < $count; $len++) {
       my $str = '';
       my %seen;
       foreach (1 .. $len-1) {
         my ($i, $value) = $seq->next;
         $str .= $value;
       }
       # ENHANCE-ME: how long does it take to see all the possible $len
       # length subwords?  1000 is enough for $len=14.
       foreach (1 .. 1000) {
         my ($i, $value) = $seq->next;
         $str .= $value;
         $str = substr($str,1);
         $seen{$str} = 1;
       }
       push @got, scalar(keys %seen);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A022156 - first differences of A020991 highest occurrence of n in cumulative

MyOEIS::compare_values
  (anum => 'A022156',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::GolayRudinShapiro->new;
     my @got;
     my $cumulative = 0;
     my @count;
     my $prev = 1;
     for (my $n = 1; @got < $count; ) {
       my ($i, $value) = $seq->next;
       $cumulative += $value;
       $count[$cumulative]++;
       if ($cumulative == $n && $count[$cumulative] >= $n) {
         if ($n >= 2) {
           push @got, $i - $prev;
         }
         $prev = $i;
         $n++;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A020987 - 0,1 values

MyOEIS::compare_values
  (anum => 'A020987',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::GolayRudinShapiro->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, ($value == 1 ? 0 : 1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A022155 - positions of -1

MyOEIS::compare_values
  (anum => 'A022155',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq = Math::NumSeq::GolayRudinShapiro->new;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == -1) {
         push @got, $i;
       }
     }
     return \@got;
   });

# A203463 - positions of 1
MyOEIS::compare_values
  (anum => 'A203463',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq = Math::NumSeq::GolayRudinShapiro->new;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 1) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A020986 - cumulative +1,-1

MyOEIS::compare_values
  (anum => 'A020986',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::GolayRudinShapiro->new;
     my @got;
     my $cumulative = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $cumulative += $value;
       push @got, $cumulative;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A020990 - cumulative with flip for low bit

MyOEIS::compare_values
  (anum => 'A020990',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::GolayRudinShapiro->new;
     my @got;
     my $cumulative = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($i & 1) {
         $value = -$value;
       }
       $cumulative += $value;
       push @got, $cumulative;
     }
     return \@got;
   });

# is also GRS(2n+1)
MyOEIS::compare_values
  (anum => 'A020990',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::GolayRudinShapiro->new;
     my @got;
     my $cumulative = 0;
     for (my $n = 1; @got < $count; $n += 2) { # odd 1,3,5,7,etc
       my $value = $seq->ith($n);
       $cumulative += $value;
       push @got, $cumulative;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A020991 - highest occurrence of n in cumulative

MyOEIS::compare_values
  (anum => 'A020991',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::GolayRudinShapiro->new;
     my @got;
     my $cumulative = 0;
     my @count;
     for (my $n = 1; @got < $count; ) {
       my ($i, $value) = $seq->next;
       $cumulative += $value;
       $count[$cumulative]++;
       if ($cumulative == $n && $count[$cumulative] >= $n) {
         push @got, $i;
         $n++;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A093573 - triangle of n as cumulative

MyOEIS::compare_values
  (anum => 'A093573',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::GolayRudinShapiro->new;
     my @got;
     my $cumulative = 0;
     my @triangle;
     for (my $n = 1; @got < $count; ) {
       my ($i, $value) = $seq->next;
       $cumulative += $value;
       my $aref = ($triangle[$cumulative] ||= []);
       push @$aref, $i;
       if ($cumulative == $n && scalar(@$aref) == $n) {
         while (@$aref && @got < $count) {
           push @got, shift @$aref;
         }
         undef $triangle[$cumulative];
         $n++;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
