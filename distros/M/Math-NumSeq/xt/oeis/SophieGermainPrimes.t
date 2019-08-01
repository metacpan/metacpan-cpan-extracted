#!/usr/bin/perl -w

# Copyright 2012, 2019 Kevin Ryde

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
plan tests => 4;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::SophieGermainPrimes;

# uncomment this to run the ### lines
#use Smart::Comments '###';


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


#------------------------------------------------------------------------------
# A053176 primes with 2*p+1 composite, ie. primes which are not SG primes
{
  my $anum = 'A053176';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my $diff;
  if ($bvalues) {
    my @got;
    my $seq  = Math::NumSeq::SophieGermainPrimes->new;
    my $primes  = Math::NumSeq::Primes->new;
    while (@got < @$bvalues) {
      my ($i, $prime) = $primes->next;
      if (! $seq->pred($prime)) {
        push @got, $prime;
      }
    }
    $diff = diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..30]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..30]));
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum");
}

#------------------------------------------------------------------------------
# A092816 - count <= 10^n
{
  my $anum = 'A092816';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum, max_count => 7);
  my $diff;
  if ($bvalues) {
    my @got;
    my $seq  = Math::NumSeq::SophieGermainPrimes->new;
    my $count = 0;
    my $target = 10;
    while (@got < @$bvalues) {
      my ($i, $prime) = $seq->next;
      if ($prime > $target) {
        push @got, $count;
        $target *= 10;
      }
      $count++;
    }
    $diff = diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..4]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..4]));
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum");
}

#------------------------------------------------------------------------------
# A156660 - 0/1 SG characteristic

{
  my $anum = 'A156660';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my $diff;
  if ($bvalues) {
    my @got;
    my $seq  = Math::NumSeq::SophieGermainPrimes->new;
    for (my $n = 0; @got < @$bvalues; $n++) {
      push @got, $seq->pred($n) ? 1 : 0;
    }
    $diff = diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..30]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..30]));
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum");
}

#------------------------------------------------------------------------------
# A156874 - count <= n

{
  my $anum = 'A156874';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my $diff;
  if ($bvalues) {
    my @got;
    my $seq  = Math::NumSeq::SophieGermainPrimes->new;
    my $count = 0;
    for (my $n = 1; @got < @$bvalues; $n++) {
      $count += $seq->pred($n);
      push @got, $count;
    }
    $diff = diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..30]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..30]));
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum");
}



#------------------------------------------------------------------------------
exit 0;
