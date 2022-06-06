#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2020 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use POSIX;
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099
use Math::Factor::XS 0.39 'prime_factors'; # version 0.39 for prime_factors()
use List::Util 'max','min';
use Math::Trig 'pi';
$|=1;

use Smart::Comments;

# use blib "$ENV{HOME}/perl/bit-vector/Bit-Vector-7.1/blib";

{
  # primes - k constant

  require Math::NumSeq::Primes;
  my $seq = Math::NumSeq::Primes->new;
  foreach my $k (1 .. 30) {
    print "k=$k\n";
    $seq->rewind;
    my @array;
    while (@array < 40) {
      my ($i, $value) = $seq->next;
      $value -= $k;
      if ($value >= 20) {
        push @array, $value;
      }
    }
    require Math::OEIS::Grep;
    Math::OEIS::Grep->search (array => \@array,
                              name => "prime - $k",
                              verbose => 1,
                             );
  }
  exit 0;
}

{
  # prime gaps

  require Math::NumSeq::Primes;
  my $seq = Math::NumSeq::Primes->new;
  my $max = 0;
  my $prev = 0;
  while (my ($i, $value) = $seq->next) {
    my $gap = $value - $prev;
    if ($gap > $max) {
      my $half = $gap/2;
      print "$i $value gap=$gap  half=$half\n";
      $max = $gap;
    }
    $prev = $value;
  }
  exit 0;
}

{
  # DivisorCount on primorials

  require Math::NumSeq::Primorials;
  require Math::NumSeq::DivisorCount;
  my $primorials = Math::NumSeq::Primorials->new;
  my $dcount = Math::NumSeq::DivisorCount->new;
  foreach (1 .. 100) {
    my ($i,$value) = $primorials->next;
    my $c = $dcount->ith($value) // 'undef';
    print "$i $c $value\n";
  }
  exit 0;
}

{
  require Math::NumSeq::PrimeFactorCount;
  require Math::NumSeq::MobiusFunction;
  require Math::NumSeq::Primorials;
  require Math::BigInt;
  my $seq = Math::NumSeq::MobiusFunction->new;
  my $i = Math::NumSeq::Primorials->new()->ith(14);
  ### $i
  # my $i = Math::BigInt->new(2)**256;
  my $value = $seq->ith($i);
  ### $value
  exit 0;
}

{
  # value_to_i_estimate()
  # require Math::NumSeq::Primes;
  # my $seq = Math::NumSeq::Primes->new;

   require Math::NumSeq::TwinPrimes;
  # my $seq = Math::NumSeq::TwinPrimes->new;

  require Math::NumSeq::SophieGermainPrimes;
  my $seq = Math::NumSeq::SophieGermainPrimes->new;

  my $target = 2;
  for (;;) {
    my ($i, $value) = $seq->next;
    if ($i >= $target) {
      $target *= 1.1;

      require Math::BigInt;
      $value = Math::BigInt->new($value);

      # require Math::BigRat;
      # $value = Math::BigRat->new($value);

      # require Math::BigFloat;
      # $value = Math::BigFloat->new($value);

      my $est_i = $seq->value_to_i_estimate($value);
      my $factor = (ref $est_i ? $est_i->numify : $est_i) / $i;
      printf "%d %d   %.10s  factor=%.3f\n",
        $i, $est_i, $value, $factor;
    }
  }
  exit 0;
}

{
  # SG density
  require Math::NumSeq::Primes;
  my $seq = Math::NumSeq::Primes->new;
  my $count_total = 0;
  my $count_primes = 0;
  my $target = 10;
  foreach (1 .. 1000) {
    my ($i, $prime) = $seq->next;
    $count_total++;
    $count_primes += is_prime(2*$prime+1);
    if ($count_total > $target) {
      my $frac = $count_primes/$count_total;
      my $log = log($count_total)/$count_total;
      print "$count_primes/$count_total = $frac  cf log=$log\n";
      $target *= 1.5;
    }
  }
  exit 0;
}

{
  # SG factorizations
  require Math::NumSeq::Primes;
  my $seq = Math::NumSeq::Primes->new;
  $, = ', ';
  foreach (1 .. 1000) {
    my ($i, $prime) = $seq->next;
    my @prime_factors = prime_factors(2*$prime+1);
    if (@prime_factors > 1) {
      print "$prime  ";
      print $prime_factors[0],"\n";
    }
  }
  exit 0;
}
{
  require Math::Prime::Util;
  {
    my $ret = Math::Prime::Util::is_prime(2**256);
    ### $ret
  }
  {
    my $approx = Math::Prime::Util::prime_count_approx(2**1024);
    ### $approx
  }
  exit 0;
}

{
  # SG speed

  require Math::NumSeq::Primes;
  require Math::NumSeq::SophieGermainPrimes;
  my $seq = Math::NumSeq::SophieGermainPrimes->new;

  require Devel::TimeThis;
  {
    my $t = Devel::TimeThis->new('seq');
    foreach (1 .. 1000) {
      $seq->next;
    }
  }
  my ($i, $prime) = $seq->next;
  {
    my $t = Devel::TimeThis->new('pred');
    foreach (1 .. $prime) {
      $seq->pred($_);
    }
  }
  my $p = Math::NumSeq::Primes->new;
  {
    my $t = Devel::TimeThis->new('p-pred');
    foreach (;;) {
      my ($i, $p) = $p->next;
      last if $p > $prime;
      $p->pred(2*$_+1);
    }
  }
  exit 0;
}




{
  # twin primes count
  use Math::NumSeq::TwinPrimes;
  my $seq = Math::NumSeq::TwinPrimes->new;

  # n	pi_2(n)
  # 10^3	35
  # 10^4	205
  # 10^5	1224
  # 10^6	8169
  # 10^7	58980
  # 10^8	440312
  # 10^9	3424506
  # 10^(10)	27412679
  # 10^(11)	224376048
  # 10^(12)	1870585220
  # 10^(13)	15834664872
  # 10^(14)	135780321665
  # 10^(15)	1177209242304
  # 10^(16)	10304195697298


  {
    my $value = 5.4e15;
    my $est_i = $seq->value_to_i_estimate($value);
    print "$value  $est_i\n";
  }


  my $target = 2;
  for (;;) {
    my ($i, $value) = $seq->next;
    if ($i >= $target) {
      $target *= 2;
      my $est_i = $seq->value_to_i_estimate($value);
      my $factor = $est_i / $i;
      printf "%d %d   %d  %.3f\n", $i, $est_i, $value, $factor;
    }
  }
  exit 0;
}



{
  # dedekind psi cumulative estimate
  require Math::NumSeq::DedekindPsiCumulative;
  my $seq = Math::NumSeq::DedekindPsiCumulative->new;

  my $target = 2;
  for (;;) {
    my ($i, $value) = $seq->next;
    if ($i >= $target) {
      $target *= 2;
      my $est_i = $seq->value_to_i_estimate($value);
      my $factor = $est_i / $i;
      my $O = ($value - (15*$i**2)/(2*pi()*pi())) / ($i*log($i));
      my $est_value = ($i**2) * 15/(2*pi()*pi()); #  + 0 * ($i*log($i));
      printf "%d %d   %d %.0f  factor=%.3f  O=%.3f\n",
        $i, $est_i, $value, $est_value, $factor, $O;
    }
  }
  exit 0;
}

{
  # deletable primes high zeros
  use Math::NumSeq::DeletablePrimes;
  my $seq = Math::NumSeq::DeletablePrimes->new;

  for my $value (0 .. 100000) {
    (my $low = $value) =~ s/.0+//
      or next;
    is_prime($value) or next;
    if ($seq->pred($value)) { next; }
    $seq->pred($low) or next;

    print "$value $low\n";
  }
  exit 0;
}


{
  # pierpont offsets

  my $offset = -7;
  foreach my $x (1 .. 20) {
    foreach my $y (1 .. 20) {
      my $v = 2**$x * 3**$y + $offset;
      last if $v > 0xFFF_FFFF;
      if ($v > 0 && is_prime($v)) {
        print "$x,$y $offset\n";
      }
    }
  }
  exit 0;
}

{
  # pierpont
  use Math::NumSeq::PierpontPrimes;
  my $seq = Math::NumSeq::PierpontPrimes->new;

  foreach (1 .. 50) {
    my ($i, $value) = $seq->next;
    my ($x, $y) = pierpont_xy ($value);
    my $cmp = ($x <=> $y);
    print "$value    $x $y      $cmp\n";
  }

  sub pierpont_xy {
    my ($value) = @_;

    my $v = $value - 1;
    my $x = 0;
    until ($v % 2) {
      $v = int($v/2);
      $x++;
    }
    my $y = 0;
    until ($v % 3) {
      $v = int($v/3);
      $y++;
    }
    return ($x, $y);
  }

  exit 0;
}


{
  require Math::Prime::FastSieve;
  my @ret = Math::Prime::FastSieve::primes(20);
  ### @ret;

  require Test::Weaken;
  my $leaks = Test::Weaken::leaks (sub { Math::Prime::FastSieve::primes(20) });
  ### $leaks

  my $sieve = Math::Prime::FastSieve::Sieve->new( 2_000_000 );
  ### isprime: $sieve->isprime(1928099)

  exit 0;
}
{
  require Math::Prime::TiedArray;
  tie my @primes, 'Math::Prime::TiedArray';
  foreach my $i (0 .. 200) {
    print int(sqrt($primes[$i])),"\n";
  }
  exit 0;
}
{
  require Math::Prime::TiedArray;
  tie my @primes, 'Math::Prime::TiedArray';
  local $, = "\n";
  print @primes[0..5000];
  exit 0;
}

{
  require Bit::Vector;
  my $size = 0xFF; # F00000;
  my $vector = Bit::Vector->new($size);
  $vector->Primes();
  print $vector->bit_test(0),"\n";
  print $vector->bit_test(1),"\n";
  print $vector->bit_test(2),"\n";
  print $vector->bit_test(3),"\n";
  print $vector->bit_test(4),"\n";
  print $vector->bit_test(5),"\n";
  print $vector->bit_test(1928099),"\n";
  foreach my $i (0 .. 100) {
    if ($vector->bit_test($i)) {
      print ",$i";
    }
  }
  print "\n";


  # require Math::Prime::XS;
  # foreach my $i (65536 .. $size-1) {
  #   my $v = 0 + $vector->bit_test($i);
  #   my $x = 0 + Math::Prime::XS::is_prime($i);
  #   if ($v != $x) {
  #     print "$i $v $x\n";
  #   }
  # }
  exit 0;
}

{
  require Math::Prime::XS;
  local $, = "\n";
  print Math::Prime::XS::sieve_primes(2,3);
  exit 0;
}
