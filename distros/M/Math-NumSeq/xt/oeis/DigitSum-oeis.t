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
plan tests => 5;


use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::DigitSum;

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


#------------------------------------------------------------------------------
# A052018 - digit sum occurs in the number

{
  my $anum = 'A052018';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq = Math::NumSeq::DigitSum->new;
    for (my $n = 0; @got < @$bvalues; $n++) {
      my ($i, $value) = $seq->next;
      if (index($i,$value) >= 0) {
        push @got, $i;
      }
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
# A180160 - sum digits mod num digits

{
  my $anum = 'A180160';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    require Math::NumSeq::DigitLength;
    my $sumseq = Math::NumSeq::DigitSum->new;
    my $lenseq = Math::NumSeq::DigitLength->new;
    for (my $n = 0; @got < @$bvalues; $n++) {
      my ($i, $sum) = $sumseq->next;
      my $len = $lenseq->ith($i);
      push @got, $sum % $len;
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
# A179083 - even with an odd sum of digits

{
  my $anum = 'A179083';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::DigitSum->new;
    for (my $n = 0; @got < @$bvalues; $n++) {
      my ($i, $value) = $seq->next;
      next if $i & 1;
      next unless $value & 1;
      push @got, $i;
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
# A137178 - hairy bit count sum
# a(n) = sum_(1..n) [S2(n)mod 2 - floor(5*S2(n)/7)mod 2],
# S2(n) = bit count = digit sum

{
  my $anum = 'A137178';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::DigitSum->new (radix => 2);
    for (my $n = 0; @got < @$bvalues; $n++) {
      my $total = 0;
      foreach my $i (1 .. $n) {
        my $s = $seq->ith($i);
        $total += ($s%2) - (int(5*$s/7) % 2);
      }
      push @got, $total;
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
# A167403 - count numbers 1 to 10^n which have sumdigits==n

{
  my $anum = 'A167403';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum,
                                                      # shorten searching
                                                      max_count => 5);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::DigitSum->new (radix => 10);
    for (my $exp = 1; @got < @$bvalues; $exp++) {
      my $count = 0;
      foreach my $n (1 .. 10 ** $exp - 1) {
        if ($seq->ith($n) == $exp) {
          $count++;
        }
      }
      push @got, $count;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..5]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..5]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1);
}

#------------------------------------------------------------------------------
exit 0;
