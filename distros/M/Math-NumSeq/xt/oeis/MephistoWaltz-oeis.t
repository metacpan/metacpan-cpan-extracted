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
use POSIX 'ceil';
use Test;
plan tests => 9;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::MephistoWaltz;


#------------------------------------------------------------------------------
# A134391 - runs 0 to 3^k-1

MyOEIS::compare_values
  (anum => 'A134391',
   max_value => 10000,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::MephistoWaltz->new;
     my @got;
     my $str = '';
     my $target = 1;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($i == $target) {
         $seq->rewind;
         $target *= 3;
       } else {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A064991 - replications as decimal bignums

MyOEIS::compare_values
  (anum => 'A064991',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::MephistoWaltz->new;
     my @got;
     require Math::BigInt;
     my $word = Math::BigInt->new(0);
     my $target = 1;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($i == $target) {
         push @got, $word;
         $target *= 3;
       }
       $word = 2*$word + $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A007051 - (3^n + 1)/2 zeros to i<3^n

MyOEIS::compare_values
  (anum => 'A007051',
   max_value => 10000,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::MephistoWaltz->new;
     my @got;
     my $num = 0;
     my $target = 1;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($i == $target) {
         push @got, $num;
         $target *= 3;
       }
       if ($value == 0) {
         $num++;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003462 - (3^n - 1)/2 ones to i<3^n

MyOEIS::compare_values
  (anum => 'A003462',
   max_value => 10000,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::MephistoWaltz->new;
     my @got;
     my $num = 0;
     my $target = 1;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($i == $target) {
         push @got, $num;
         $target *= 3;
       }
       if ($value == 1) {
         $num++;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A156595 - xor diffs

MyOEIS::compare_values
  (anum => 'A156595',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::MephistoWaltz->new;
     my @got;
     my ($i, $prev) = $seq->next;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $prev ^ $value;
       $prev = $value;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A156595',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, calc_A156595($n);
     }
     return \@got;
   });

sub calc_A156595 {
  my ($n) = @_;

  # return ternary2s($n) ^ ternary2s($n+1);
  # N+1 changes 2s once for each trailing 2 and then once more if 1-trit
  # above that.
  # ...1222..22 + 1 = ...2000..00

  my $ret = 0;
  for (;;) {
    my $rem = $n % 3;
    $n = ($n-$rem)/3;
    if ($rem == 0) {
      last;
    }
    if ($rem == 1) {
      $ret ^= 1;
      last;
    }
    if ($rem == 2) {
      $ret ^= 1;
    }
  }
  return $ret;
}
sub ternary2s {
  my ($n) = @_;
  my $ret = 0;
  while ($n) {
    my $rem = $n % 3;
    $n = ($n-$rem)/3;
    if ($rem == 2) {
      $ret ^= 1;
    }
  }
  return $ret;
}

#------------------------------------------------------------------------------
# A189658 - positions of 0s, but n+1 so counting from value=1 for the first

MyOEIS::compare_values
  (anum => 'A189658',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::MephistoWaltz->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 0) {
         push @got, $i + 1;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A189659 - positions of 1s, but n+1 so counting from value=1 for the first

MyOEIS::compare_values
  (anum => 'A189659',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::MephistoWaltz->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 1) {
         push @got, $i + 1;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A189660 - cumulative

MyOEIS::compare_values
  (anum => 'A189660',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::MephistoWaltz->new;
     my @got;
     my $total = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $total += $value;
       push @got, $total;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
