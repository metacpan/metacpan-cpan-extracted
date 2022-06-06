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
plan tests => 11;


use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::DigitCount;


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
# A052382 numbers without 0 digit

{
  my $anum = 'A052382';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::DigitCount->new (radix => 10, digit => 0);
    $seq->next; # skip i=0
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      if ($value == 0) {
        push @got, $i;
      }
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum");
}

#------------------------------------------------------------------------------
# A071858 count 1 bits, mod 3

{
  my $anum = 'A071858';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::DigitCount->new (radix => 2, digit => 1);
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      push @got, $value % 3;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- count 1-bits, mod 3");
}

#------------------------------------------------------------------------------
# A077268 - num bases with at least one 0

{
  my $anum = 'A077268';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    for (my $n = 1; @got < @$bvalues; $n++) {
      my $count = 0;
      foreach my $radix (2 .. $n) {
        my $seq  = Math::NumSeq::DigitCount->new (radix => $radix, digit => 0);
        if ($seq->ith($n)) {
          $count++;
        }
      }
      push @got, $count;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- num bases with at least one 0");
}


#------------------------------------------------------------------------------
# A077266 - triangle count 0s in bases 2 to n

{
  my $anum = 'A077266';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
  OUTER: for (my $n = 1; ; $n++) {
      foreach my $radix (2 .. $n) {
        my $seq  = Math::NumSeq::DigitCount->new (radix => $radix, digit => 0);
        push @got, $seq->ith($n);
        last OUTER if @got >= @$bvalues;
      }
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- triangle count 0s in bases 2 to n");
}

#------------------------------------------------------------------------------
# A033093 - total count 0s in bases 2 to n+1

{
  my $anum = 'A033093';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    for (my $n = 1; @got < @$bvalues; $n++) {
      my $total = 0;
      foreach my $radix (2 .. $n+1) {
        my $seq  = Math::NumSeq::DigitCount->new (radix => $radix, digit => 0);
        $total += $seq->ith($n);
      }
      push @got, $total;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- total count 0s in bases 2 to n+1");
}


#------------------------------------------------------------------------------
# A059015 - cumulative 0-bit count

{
  my $anum = 'A059015';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::DigitCount->new (radix => 2, digit => 0);
    my $cumulative = 1;  # reckoning 0 as a single 0-bit, maybe
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      $cumulative += $value;
      push @got, $cumulative;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- cumulative 1-bit count");
}

#------------------------------------------------------------------------------
# A000788 - cumulative 1-bit count

{
  my $anum = 'A000788';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::DigitCount->new (radix => 2, digit => 1);
    my $cumulative = 0;
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      $cumulative += $value;
      push @got, $cumulative;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- cumulative 1-bit count");
}

#------------------------------------------------------------------------------
# A000069 - "odious", odd count of 1-bits

{
  my $anum = 'A000069';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::DigitCount->new (radix => 2, digit => 1);
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      if ($value % 2) {  # odd number of 1 bits
        push @got, $i;
      }
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- odious odd 1-bit count");
}

#------------------------------------------------------------------------------
# A001969 - "evil", even count of 1-bits

{
  my $anum = 'A001969';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::DigitCount->new (radix => 2, digit => 1);
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      if ($value % 2 == 0) {  # odd number of 1 bits
        push @got, $i;
      }
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- evil even 1-bit count");
}

#------------------------------------------------------------------------------
# A023416 - count 0-bits, but treating 0 as a single 0-bit

{
  my $anum = 'A023416';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::DigitCount->new (radix => 2, digit => 0);
    $seq->next;
    push @got, 1;
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      push @got, $value;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- count 0-bits, with zero as a single 0-bits");
}

#------------------------------------------------------------------------------
# A159918 - count 1-bits in the squares

{
  my $anum = 'A159918';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::DigitCount->new (radix => 2, digit => 1);
    for (my $i = 0; @got < @$bvalues; $i++) {
      push @got, $seq->ith($i*$i);
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- count 1-bits in the squares");
}

#------------------------------------------------------------------------------
exit 0;
