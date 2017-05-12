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
plan tests => 2;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::CollatzSteps;

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------
# A070917 - steps are a divisor of n

MyOEIS::compare_values
  (anum => 'A070917',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::CollatzSteps->new;
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value && $i % $value == 0) {
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# steps starting 64*n+offset

{
  my $seq = Math::NumSeq::CollatzSteps->new (end_type => 'drop');

  foreach my $elem ([ 'A075476', 7 ],
                    [ 'A075477', 15 ],
                    [ 'A075478', 27 ],
                    [ 'A075479', 31 ],
                    [ 'A075480', 39 ],
                    [ 'A075481', 47 ],
                    [ 'A075482', 59 ],
                    [ 'A075483', 63 ]) {
    my ($anum,$offset) = @$elem;

    MyOEIS::compare_values
        (anum => $anum,
         func => sub {
           my ($count) = @_;
           my @got;
           for (my $n = $offset; @got < $count; $n += 64) {
             push @got, $seq->ith($n) + 1;
           }
           return \@got;
         });
  }
}

#------------------------------------------------------------------------------
# A070975 - steps starting prime(n)

MyOEIS::compare_values
  (anum => 'A070975',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $seq = Math::NumSeq::CollatzSteps->new;
     my $primes = Math::NumSeq::Primes->new;
     my @got;
     while (@got < $count) {
       my ($i,$value) = $primes->next;
       push @got, $seq->ith($value);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A070976 - steps starting 3^n

MyOEIS::compare_values
  (anum => 'A070976',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::CollatzSteps->new;
     my @got;
     my $i = Math::NumSeq::_to_bigint(1);
     while (@got < $count) {
       push @got, $seq->ith($i);
       $i *= 3;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A070974 - steps starting n!

MyOEIS::compare_values
  (anum => 'A070974',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Factorials;
     my $seq = Math::NumSeq::CollatzSteps->new;
     my $fac = Math::NumSeq::Factorials->new;
     $fac->seek_to_i(1);
     my @got;
     while (@got < $count) {
       my ($i,$value) = $fac->next;
       push @got, $seq->ith($value);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A179118 - steps starting 2^n + 1

MyOEIS::compare_values
  (anum => 'A179118',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::CollatzSteps->new;
     my @got;
     my $i = Math::NumSeq::_to_bigint(1);
     while (@got < $count) {
       $i *= 2;
       push @got, $seq->ith($i+1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A193688 - steps starting 2^n - 1

MyOEIS::compare_values
  (anum => 'A193688',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::CollatzSteps->new;
     my @got;
     my $i = Math::NumSeq::_to_bigint(1);
     while (@got < $count) {
       push @got, $seq->ith($i);
       $i = 2*$i + 1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A186701 - partial sums of A008908 which is steps+1 which is on_values=even

MyOEIS::compare_values
  (anum => 'A186701',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::CollatzSteps->new (on_values => 'even');
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
# A058633 - cumulative

MyOEIS::compare_values
  (anum => 'A058633',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::CollatzSteps->new;
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
# A006884 - new highest point in trajectory

# {
#   my $anum = 'A006884';
#   my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
#   my $diff;
#   if ($bvalues) {
#     my $seq = Math::NumSeq::CollatzSteps->new;
#     my $target = 1;
#     my @got;
#     while (@got < @$bvalues) {
#       my ($i, $value) = $seq->next;
#       if ($value >= $target) {
#         push @got, $i;
#         $target++;
#       }
#     }
#     $diff = diff_nums(\@got, $bvalues);
#     if ($diff) {
#       MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
#       MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
#     }
#   }
#   skip (! $bvalues,
#         $diff, undef,
#         "$anum - new high count of steps");
# }

#------------------------------------------------------------------------------

exit 0;
