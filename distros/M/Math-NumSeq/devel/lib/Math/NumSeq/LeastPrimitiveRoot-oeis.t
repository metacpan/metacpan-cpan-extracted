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



 # A046145     Smallest primitive root modulo n, or 0 if no root exists.    16  
# A002322 Reduced totient function psi(n): least k such that x^k == 1 (mod n) for all x prime to n; also known as the Carmichael lambda function (exponent of unit group mod n); also called the universal exponent of n.
# A111076 Smallest number of maximal order mod n.
# A011773 Variant of Carmichael's lambda function: a(p1^e1*...*pN^eN) = LCM((p1-1)*p1^(e1-1),...,(pN-1)*pN^(eN-1)).
# A034380 Ratio of totient to Carmichael's lambda function: a(n) = A000010(n) / A002322(n).
# A062373 Ratio of totient to Carmichael's lambda function is 2.
# A062374 Euler phi(n) / Carmichael lambda(n) = 4.
# A062375 Euler phi(n) / Carmichael lambda(n) = 6.
# A062376 Euler phi(n) / Carmichael lambda(n) = 8.
# A062377 Euler phi(n) / Carmichael lambda(n) = 10.
# A066497 Least number k such that phi(k) / Carmichael lambda(k) = 2n.
# A066605 Numbers n such that phi(n) / Carmichael lambda(n) = increases.
# A066695 Euler phi(n) / Carmichael lambda(n) = 12.
# A066696 Euler phi(n) / Carmichael lambda(n) = 14.
# A066697 Euler phi(n) / Carmichael lambda(n) = 18.
# A066698 Euler phi(n) / Carmichael lambda(n) = 34.
# A104196 Sum of CarmichaelLambda[n] between successive powers of 2.
# A104194 a(n) = EulerPhi[n]-CarmichaelLambda[n] (cf. A000010, A002322).
# A123101 lambda(phi(n))=phi(lambda(n)) for the sequential application of Euler totient and Carmichael lambda functions.
# A124240 Numbers n such that lambda(n) divides n, where lambda is Carmichael's function, A002322.
# A131492 Numbers n such that the sum of the Carmichael lambda functions of the divisors is a proper divisor of n.
# A162578 Partial sums of the Carmichael lambda function A002322.
# A173694 Arguments n for which the Carmichael lambda function A002322(n) is a perfect square.
# A173927 Smallest integer k such that the number of iterations of Carmichael lambda function (A002322) needed to reach 1 starting at k (k is counted) is n.
# A181776 a(n) = lambda(lambda(n)), where lambda(n) is the Carmichael lambda function (A002322).
# A187730 Greatest common divisor of Carmichael lambda(n) and n - 1.
# A207193 Auxiliary function for computing the Carmichael lambda function (A002322).
# A214428 Carmichael numbers n such that lambda(n) = 2^k * p, where lambda is the Carmichael lambda function, k is an integer, and p is a prime.



use 5.004;
use strict;
use List::Util 'min','max';

use Test;
plan tests => 7;

use lib 't','xt',              'devel/lib';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::LeastPrimitiveRoot;

# uncomment this to run the ### lines
# use Smart::Comments '###';


#------------------------------------------------------------------------------
# A033947 - least positive or negative primitive root of primes

MyOEIS::compare_values
  (anum => 'A033947',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $primes = Math::NumSeq::Primes->new;
     my $pos_seq = Math::NumSeq::LeastPrimitiveRoot->new;
     my $neg_seq = Math::NumSeq::LeastPrimitiveRoot->new (root_type => 'negative');
     my @got;
     while (@got < $count) {
       my ($i, $prime) = $primes->next or last;
       my $pos_root = $pos_seq->ith($prime);
       my $neg_root = $neg_seq->ith($prime);
       push @got, ($pos_root <= -$neg_root ? $pos_root : $neg_root);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A001122-A001126 - primes with least primitive root 2, 3, etc

foreach my $elem ([2,'A001122'],
                  [3,'A001123'],
                  [4,'A001124'],
                  [5,'A001125'],
                  [6,'A001126'],
                 ) {
  my ($want_root,$anum) = @$elem;

  require Math::NumSeq::Primes;
  MyOEIS::compare_values
      (anum => $anum,
       func => sub {
         my ($count) = @_;
         my $primes = Math::NumSeq::Primes->new;
         my $seq = Math::NumSeq::LeastPrimitiveRoot->new;
         my @got;
         while (@got < $count) {
           my ($i, $prime) = $primes->next or last;
           my $root = $seq->ith($prime);
           if ($root == $want_root) {
             push @got, $prime;
           }
         }
         return \@got;
       }
      );
}


#------------------------------------------------------------------------------
# A002322 - Carmichael lambda

MyOEIS::compare_values
  (anum => 'A002322',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       push @got, Math::NumSeq::LeastPrimitiveRoot::_lambda($n)
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A181776 - lambda(lambda(n))

MyOEIS::compare_values
  (anum => 'A181776',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       push @got,
         Math::NumSeq::LeastPrimitiveRoot::_lambda
             (Math::NumSeq::LeastPrimitiveRoot::_lambda($n));
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A173694 -- n for which lambda(n) is a perfect square

MyOEIS::compare_values
  (anum => 'A173694',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Squares;
     my $squares = Math::NumSeq::Squares->new;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       my $lambda = Math::NumSeq::LeastPrimitiveRoot::_lambda($n);
       if ($squares->pred($lambda)) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A023048 - least prime with least primitive root n

{
  my $max_value = 100_000;
  MyOEIS::compare_values
      (anum => 'A023048',
       max_value => $max_value,
       func => sub {
         my ($count) = @_;
         require Math::NumSeq::Primes;
         my $primes = Math::NumSeq::Primes->new;
         my $seq = Math::NumSeq::LeastPrimitiveRoot->new;
         my @got;
         $got[1] = 2;

         for (;;) {
           my ($i, $prime) = $primes->next or last;
           last if $prime > $max_value;
           my $root = $seq->ith($prime);
           if ($root < $count) {
             $got[$root] ||= $prime;
           }
         }
         foreach (@got) { $_ ||= 0 }
         shift @got; # not 0

         return \@got;
       });
}

#------------------------------------------------------------------------------
# A002199 - least negative primitive root of primes

MyOEIS::compare_values
  (anum => 'A002199',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $primes = Math::NumSeq::Primes->new;
     my $seq = Math::NumSeq::LeastPrimitiveRoot->new (root_type => 'negative');
     my @got;
     while (@got < $count) {
       my ($i, $prime) = $primes->next or last;
       push @got, - $seq->ith($prime);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A002230 - primes with new record least primitive root

MyOEIS::compare_values
  (anum => 'A002230',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $primes = Math::NumSeq::Primes->new;
     my $seq = Math::NumSeq::LeastPrimitiveRoot->new;
     my $record = 0;
     my @got;
     while (@got < $count) {
       my ($i, $prime) = $primes->next or last;
       my $root = $seq->ith($prime);
       if ($root > $record) {
         push @got, $prime;
         $record = $root;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A001122 - primes with 2 as primitive root

MyOEIS::compare_values
  (anum => 'A001122',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $primes = Math::NumSeq::Primes->new;
     my $seq = Math::NumSeq::LeastPrimitiveRoot->new;
     my @got;
     while (@got < $count) {
       my ($i, $prime) = $primes->next or last;
       if ($seq->ith($prime) == 2) {
         push @got, $prime;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A071894 - largest primitive root of primes

MyOEIS::compare_values
  (anum => 'A071894',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $primes = Math::NumSeq::Primes->new;
     my $seq = Math::NumSeq::LeastPrimitiveRoot->new (root_type => 'negative');
     my @got;
     while (@got < $count) {
       my ($i, $prime) = $primes->next or last;
       push @got, $prime + $seq->ith($prime);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A111076 - least primitive lambda root of all integers

MyOEIS::compare_values
  (anum => 'A111076',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::LeastPrimitiveRoot->new;
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A001918 - least primitive root of primes

MyOEIS::compare_values
  (anum => 'A001918',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $primes = Math::NumSeq::Primes->new;
     my $seq = Math::NumSeq::LeastPrimitiveRoot->new;
     my @got;
     while (@got < $count) {
       my ($i, $prime) = $primes->next or last;
       push @got, $seq->ith($prime);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A114885 - primes with new record least primitive root, the prime index

MyOEIS::compare_values
  (anum => 'A114885',
   max_value => 50_000,
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $primes = Math::NumSeq::Primes->new;
     my $seq = Math::NumSeq::LeastPrimitiveRoot->new;
     my $record = 0;
     my @got;
     while (@got < $count) {
       my ($i, $prime) = $primes->next or last;
       my $root = $seq->ith($prime);
       if ($root > $record) {
         push @got, $i;
         $record = $root;
       }
     }
     return \@got;
   });

# #------------------------------------------------------------------------------
# # A029932 - primes with new record least primitive root which is a prime
#
# {
#   my $anum = 'A029932';
#   my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum,
#                                                       max_value => 100_000);
#   my $diff;
#   if ($bvalues) {
#     my $primes = Math::NumSeq::Primes->new;
#     my $seq = Math::NumSeq::LeastPrimitiveRoot->new;
#     my $record = 0;
#     my @got;
#     while (@got < @$bvalues) {
#       my ($i, $prime) = $primes->next or last;
#       my $root = $seq->ith($prime);
#       next unless $primes->pred($root);
#       if ($root > $record) {
#         push @got, $prime;
#         $record = $root;
#       }
#     }
#     $diff = diff_nums(\@got, $bvalues);
#     if ($diff) {
#       MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..10]));
#       MyTestHelpers::diag ("got:     ",join(',',@got[0..10]));
#     }
#   }
#   skip (! $bvalues,
#         $diff, undef,
#         "$anum");
# }
#
# #------------------------------------------------------------------------------
# # A002231 - primes with new record least primitive root which is a prime, the roots
#
# {
#   my $anum = 'A002231';
#   my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum,
#                                                       max_count => 10);
#   my $diff;
#   if ($bvalues) {
#     my $primes = Math::NumSeq::Primes->new;
#     my $seq = Math::NumSeq::LeastPrimitiveRoot->new;
#     my $record = 0;
#     my @got;
#     while (@got < @$bvalues) {
#       my ($i, $prime) = $primes->next or last;
#       my $root = $seq->ith($prime);
#       next unless $primes->pred($root);
#       if ($root > $record) {
#         push @got, $root;
#         $record = $root;
#       }
#     }
#     $diff = diff_nums(\@got, $bvalues);
#     if ($diff) {
#       MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..10]));
#       MyTestHelpers::diag ("got:     ",join(',',@got[0..10]));
#     }
#   }
#   skip (! $bvalues,
#         $diff, undef,
#         "$anum");
# }

#------------------------------------------------------------------------------
exit 0;
