#!/usr/bin/perl -w

# Copyright 2012, 2013, 2020, 2021, 2022 Kevin Ryde

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
plan tests => 17;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::Primes;

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

#------------------------------------------------------------------------------
# A004676 - primes in binary

MyOEIS::compare_values
  (anum => 'A004676',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $primes = Math::NumSeq::Primes->new;
     my @got;
     while (@got < $count) {
       my ($i, $prime) = $primes->next;
       push @got, sprintf '%b', $prime;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A090423 - primes binary concat of others

MyOEIS::compare_values
  (anum => 'A090423',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::Primes;
     my $primes = Math::NumSeq::Primes->new;
     my @strings;
     my @got;
     while (@got < $count) {
       my ($i, $prime) = $primes->next;
       my $prime2 = sprintf '%b', $prime;
       if (@strings) {
         my $re = '^('.join('|',@strings).')*$';
         if ($prime2 =~ $re) {
           push @got, $prime;
         }
       }
       push @strings, $prime2;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A145445 - smallest square > nth prime

{
  my $anum = 'A145445';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);

  my $diff;
  if ($bvalues) {
    require Math::NumSeq::Squares;
    my @got;
    my $seq  = Math::NumSeq::Primes->new;
    my $squares = Math::NumSeq::Squares->new;
    while (@got < @$bvalues) {
      my ($i, $prime) = $seq->next;
      my $sqrt = $squares->value_to_i_ceil($prime);
      push @got, $sqrt*$sqrt;
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
# A104103 - ceil(sqrt(prime))
# cf A177357 squares <= prime(n)-3

{
  my $anum = 'A104103';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  {
    my $diff;
    if ($bvalues) {
      my @got;
      my $seq  = Math::NumSeq::Primes->new;
      while (@got < @$bvalues) {
        my ($i, $prime) = $seq->next;
        push @got, ceil(sqrt($prime));
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

  # count squares <= prime, including 0 as a square
  {
    my $diff;
    if ($bvalues) {
      my @got;
      my $seq  = Math::NumSeq::Primes->new;
      my $count = 0;
      my $root = 0;
      my $square = 0;
      while (@got < @$bvalues) {
        my ($i, $prime) = $seq->next;
        while ($square <= $prime) {
          $count++;
          $root++;
          $square = $root*$root;
        }
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
}

#------------------------------------------------------------------------------
# A003627 - primes 3k-1

{
  my $anum = 'A003627';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::Primes->new;
    while (@got < @$bvalues) {
      my ($i, $prime) = $seq->next;
      if (($prime % 3) == 2) {
        push @got, $prime;
      }
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1);
}

#------------------------------------------------------------------------------
# A092178 - primes == 8 mod 13

{
  my $anum = 'A092178';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::Primes->new;
    while (@got < @$bvalues) {
      my ($i, $prime) = $seq->next;
      if (($prime % 13) == 8) {
        push @got, $prime;
      }
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1);
}

#------------------------------------------------------------------------------
# A111333 - count odd numbers up to n'th prime

{
  my $anum = 'A111333';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::Primes->new;
    my ($i, $prime) = $seq->next;
    my $count = 0;
    for (my $odd = 1; @got < @$bvalues; $odd += 2) {
      if ($odd > $prime) {
        push @got, $count;
        ($i, $prime) = $seq->next;
      }
      $count++;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1);
}

#------------------------------------------------------------------------------
# A035103 - count 0-bits in primes

{
  my $anum = 'A035103';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    require Math::NumSeq::DigitCount;
    my $count = Math::NumSeq::DigitCount->new (radix=>2,digit=>0);
    my $seq  = Math::NumSeq::Primes->new;
    while (@got < @$bvalues) {
      my ($i, $prime) = $seq->next;
      push @got, $count->ith($prime);
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1);
}

#------------------------------------------------------------------------------
# A147849 - next triangular > each prime

{
  my $anum = 'A147849';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    require Math::NumSeq::Triangular;
    my $triangular = Math::NumSeq::Triangular->new;
    my $seq  = Math::NumSeq::Primes->new;
    while (@got < @$bvalues) {
      my ($i, $prime) = $seq->next;
      my $ti = $triangular->value_to_i_floor($prime) + 1; # strictly greater
      push @got, $triangular->ith($ti);
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1);
}

#------------------------------------------------------------------------------
# A097050 - next prime > each triangular

{
  my $anum = 'A097050';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my $diff;
  if ($bvalues) {
    my @got;
    require Math::NumSeq::Triangular;
    my $triangular = Math::NumSeq::Triangular->new;
    my $seq  = Math::NumSeq::Primes->new;
    (undef, my $target) = $triangular->next;
    while (@got < @$bvalues) {
      (undef, my $prime) = $seq->next;
      while ($prime > $target) {   # same prime 2 after triangular 0 and 1
        push @got, $prime;
        (undef, $target) = $triangular->next;
      }
    }
    $diff = diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum");
}

#------------------------------------------------------------------------------
# A002808 - composites, excluding 1

{
  my $anum = 'A002808';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::Primes->new;
    my $upto = 2;
  OUTER: for (;;) {
      my ($i, $prime) = $seq->next;
      while ($upto < $prime) {
        push @got, $upto++;
        last OUTER unless @got < @$bvalues;
      }
      $upto++; # skip $prime
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- non-primes");
}

#------------------------------------------------------------------------------
# A018252 - composites, including 1

{
  my $anum = 'A018252';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::Primes->new;
    my $upto = 1;
  OUTER: for (;;) {
      my ($i, $prime) = $seq->next;
      while ($upto < $prime) {
        push @got, $upto++;
        last OUTER unless @got < @$bvalues;
      }
      $upto++; # skip $prime
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- non-primes");
}


#------------------------------------------------------------------------------
# A143538 - rows T(n,k)=0,1 according as k prime

{
  my $anum = 'A143538';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::Primes->new;
    for (my $n = 0; @got < @$bvalues; $n++) {
      for (my $k = 1; $k < $n && @got < @$bvalues; $k++) {
        push @got, $seq->pred($k) ? 1 : 0;
      }
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- triangular T(n,k) 0,1 prime k");
}


#------------------------------------------------------------------------------
# A010051 - characteristic boolean 0 or 1 according as N is prime

{
  my $anum = 'A010051';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::Primes->new;
    for (my $i = 1; @got < @$bvalues; $i++) {
      push @got, $seq->pred($i) ? 1 : 0;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- 0/1 boolean");
}

#------------------------------------------------------------------------------
# A000720 - pi(n) num primes <= n

{
  my $anum = 'A000720';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::Primes->new;
    my $count = 0;
    for (my $i = 1; @got < @$bvalues; $i++) {
      $count += $seq->pred($i);
      push @got, $count;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- pi(n) count");
}

#------------------------------------------------------------------------------
# A036234 - pi(n) num primes <= n, with 1 counted as a prime

{
  my $anum = 'A036234';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $seq  = Math::NumSeq::Primes->new;
    my $count = 1;
    push @got, $count;
    for (my $i = 2; @got < @$bvalues; $i++) {
      $count += $seq->pred($i);
      push @got, $count;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- pi(n) count");
}

#------------------------------------------------------------------------------
exit 0;
