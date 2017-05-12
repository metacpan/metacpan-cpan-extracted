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
plan tests => 35;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::FibbinaryBitCount;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A111458 fibbinary bit count > 3

MyOEIS::compare_values
  (anum => 'A111458',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::FibbinaryBitCount->new;
     my @got;
     $seq->seek_to_i(2);  # not 0 or 1
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value > 3) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A059389 fibbinary bit count <= 2
#   two distinct non-zero Fibs not necessarily the biggest

MyOEIS::compare_values
  (anum => 'A059389',
   max_value => 100000,
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::FibbinaryBitCount->new;
     my @got;
     $seq->seek_to_i(2);  # not 0 or 1
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value <= 2) {
         push @got, $i;
       }
     }
     return \@got;
   });

# A059390 fibbinary bit count > 2
MyOEIS::compare_values
  (anum => 'A059390',
   max_value => 100000,
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::FibbinaryBitCount->new;
     my @got = (1);
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value > 2) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A095096 numbers with even num Zeck 1-bits

MyOEIS::compare_values
  (anum => 'A095096',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::FibbinaryBitCount->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value % 2 == 0) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A095076 fibbinary bit count mod 2

MyOEIS::compare_values
  (anum => 'A095076',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my $seq  = Math::NumSeq::FibbinaryBitCount->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value % 2;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A182578 Number of ones in Zeckendorf representation of n^n.

MyOEIS::compare_values
  (anum => 'A182578',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my $seq  = Math::NumSeq::FibbinaryBitCount->new;
     my @got;
     for (my $i = Math::BigInt->new(0); @got < $count; $i++) {
       push @got, $seq->ith($i**$i);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A182575 - primes with equal number of Zeck 1-bits and 0-bits

MyOEIS::compare_values
  (anum => 'A182575',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $cnt1 = Math::NumSeq::FibbinaryBitCount->new;
     my $cnt0 = Math::NumSeq::FibbinaryBitCount->new (digit => 0);
     my $primes = Math::NumSeq::Primes->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $primes->next;
       if ($cnt0->ith($value) == $cnt1->ith($value)) {
         push @got, $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A182569 - primes with 2 etc terms in Zeckendorf base

foreach my $elem ([ 2, 'A182569'],
                  [ 3, 'A182570'],
                  [ 4, 'A182571'],
                  [ 5, 'A182572'],
                  [ 6, 'A182573'],
                  [ 7, 'A182574'],
                 ) {
  my ($want_terms, $anum) = @$elem;

  MyOEIS::compare_values
      (anum => $anum,
       max_value => 1_000_000,
       func => sub {
         my ($count) = @_;
         require Math::NumSeq::Primes;
         my $primes = Math::NumSeq::Primes->new;
         my $fibcnt = Math::NumSeq::FibbinaryBitCount->new;
         my @got;
         while (@got < $count) {
           my ($i, $value) = $primes->next;
           if ($fibcnt->ith($value) == $want_terms) {
             push @got, $value;
           }
         }
         return \@got;
       }
      );
}

#------------------------------------------------------------------------------
# A179242 - numbers with 2 etc terms in Zeckendorf base

foreach my $elem ([ 2, 'A179242'],
                  [ 3, 'A179243'],
                  [ 4, 'A179244'],
                  [ 5, 'A179245'],
                  [ 6, 'A179246'],
                  [ 7, 'A179247'],
                  [ 8, 'A179248'],
                  [ 9, 'A179249'],
                  [10, 'A179250'],
                  [11, 'A179251'],
                  [12, 'A179252'],
                  [13, 'A179253'],
                 ) {
  my ($want_terms, $anum) = @$elem;

  MyOEIS::compare_values
      (anum => $anum,
       func => sub {
         my ($count) = @_;
         my $seq  = Math::NumSeq::FibbinaryBitCount->new;
         my @got;
         while (@got < $count) {
           my ($i, $value) = $seq->next;
           if ($value == $want_terms) {
             push @got, $i;
           }
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A182535 - number of Zeck 1-bits in each prime

MyOEIS::compare_values
  (anum => 'A182535',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $fibcnt = Math::NumSeq::FibbinaryBitCount->new;
     my $primes = Math::NumSeq::Primes->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $primes->next;
       push @got, $fibcnt->ith($value);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A182577 - number of 1-bits in Zeckendorf of i=n!

MyOEIS::compare_values
  (anum => 'A182577',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Factorials;
     my $fibcnt = Math::NumSeq::FibbinaryBitCount->new;
     my $fact = Math::NumSeq::Factorials->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $fact->next;
       push @got, $fibcnt->ith($value);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A182576 - number of 1-bits in Zeckendorf of i=n^2

MyOEIS::compare_values
  (anum => 'A182576',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::FibbinaryBitCount->new;
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       push @got, $seq->ith($i*$i);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A020908 - number of 1-bits in Zeckendorf of i=2^k etc

foreach my $elem ([ 2, 'A020908'],
                  [ 3, 'A020910'],
                  [ 4, 'A025496'],
                  [ 5, 'A025497'],
                  [ 6, 'A025498'],
                  [ 7, 'A025499'],
                  [ 8, 'A025500'],
                  [ 9, 'A025501'],
                  [10, 'A025502'],
                 ) {
  my ($base, $anum) = @$elem;

  MyOEIS::compare_values
      (anum => $anum,
       func => sub {
         my ($count) = @_;
         require Math::BigInt;
         my $seq  = Math::NumSeq::FibbinaryBitCount->new;
         my @got;
         my $i = Math::NumSeq::_to_bigint(1);
         while (@got < $count) {
           push @got, $seq->ith($i);
           $i *= $base;
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A020899 - numbers with odd num 1-bits in Zeckendorf

MyOEIS::compare_values
  (anum => 'A020899',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::FibbinaryBitCount->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value % 2) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A095111 - fibbinary bit count parity, flipped 0 <-> 1

MyOEIS::compare_values
  (anum => 'A095111',
   func => sub {
     my ($count) = @_;
     my $seq  = Math::NumSeq::FibbinaryBitCount->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, ($value % 2) ^ 1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A027941 - new high bit count, being Fibonacci(2i+1)-1

MyOEIS::compare_values
  (anum => 'A027941',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::FibbinaryBitCount->new;
     my $target = 0;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value >= $target) {
         push @got, $i;
         $target++;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
