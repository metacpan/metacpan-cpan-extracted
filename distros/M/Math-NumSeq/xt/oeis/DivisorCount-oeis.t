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
plan tests => 2;


use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::DivisorCount;

# uncomment this to run the ### lines
#use Smart::Comments '###';


sub numeq_array {
  my ($a1, $a2) = @_;
  if (! ref $a1 || ! ref $a2) {
    return 0;
  }
  my $i = 0; 
  while ($i < @$a1 && $i < @$a2) {
    if ($a1->[$i] ne $a2->[$i]) {
      return 0;
    }
    $i++;
  }
  return (@$a1 == @$a2);
}

sub diff_nums {
  my ($gotaref, $wantaref) = @_;
  for (my $i = 0; $i < @$gotaref; $i++) {
    if ($i > @$wantaref) {
      return "want ends prematurely pos=$i";
    }
    my $got = $gotaref->[$i];
    my $want = $wantaref->[$i];
    if (! defined $got && ! defined $want) {
      next;
    }
    if (! defined $got || ! defined $want) {
      return "different pos=$i got=".(defined $got ? $got : '[undef]')
        ." want=".(defined $want ? $want : '[undef]');
    }
    $got =~ /^[0-9.-]+$/
      or return "not a number pos=$i got='$got'";
    $want =~ /^[0-9.-]+$/
      or return "not a number pos=$i want='$want'";
    if ($got != $want) {
      return "different pos=$i numbers got=$got want=$want";
    }
  }
  return undef;
}



# No, counts factorizations.
# #------------------------------------------------------------------------------
# # A033833 - new high count of divisors
# 
# {
#   my $anum = 'A033833';
#   my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum,
# max_value => 1000);
#   my @got;
#   if ($bvalues) {
#     my $seq  = Math::NumSeq::DivisorCount->new;
#     my $max_value = 0;
#     for (my $i = 1; @got < @$bvalues; $i++) {
#       my $value = $seq->ith($i);
#       if ($value > $max_value) {
#         push @got, $i;
#         $max_value = $value;
#       }
#     }
#     if (! numeq_array(\@got, $bvalues)) {
#       MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..5]));
#       MyTestHelpers::diag ("got:     ",join(',',@got[0..5]));
#     }
#   }
#   skip (! $bvalues,
#         numeq_array(\@got, $bvalues),
#         1,
#         "$anum");
# }

#------------------------------------------------------------------------------
# A005179 - smallest number with n divisors

{
  my $anum = 'A005179';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum, max_count => 20);
  my $diff;
  if ($bvalues) {
    my $seq  = Math::NumSeq::DivisorCount->new;
    my $count = 0;
    my ($i, $value);
    my @got;
    while ($count < @$bvalues) {
      ($i, $value) = $seq->next;
      ### $i
      ### $value
      if ($value <= @$bvalues) {
        if (! defined $got[$value-1]) {
          $got[$value-1] = $i;
          $count++;
        }
      }
    }
    $diff = diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..9]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..9]));
      MyTestHelpers::diag ("  stopped at i=$i value=$value");
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum");
}

#------------------------------------------------------------------------------
# A137179 - smallest m with divcount(m)+divcount(m+1) == n

{
  my $anum = 'A137179';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::DivisorCount->new;
  OUTER: for (my $n = 3; @got < @$bvalues; $n++) {
      foreach my $m (1 .. 100000) {
        my $d1 = $seq->ith($m);
        my $d2 = $seq->ith($m+1);
        if ($d1+$d2 == $n) {
          push @got, $m;
          next OUTER;
        }
      }
      die "Oops, no sum equal $n";
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..5]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..5]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1,
        "$anum");
}

#------------------------------------------------------------------------------
# A092405 - divcount(i)+divcount(i+1)

{
  my $anum = 'A092405';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::DivisorCount->new;
    for (my $n = 1; @got < @$bvalues; $n++) {
      push @got, $seq->ith($n) + $seq->ith($n+1);
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..5]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..5]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1,
        "$anum");
}

#------------------------------------------------------------------------------
exit 0;
