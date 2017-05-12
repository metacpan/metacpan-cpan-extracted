#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013 Kevin Ryde

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
use List::Util 'max';
use Math::Factor::XS 0.39 'prime_factors'; # version 0.39 for prime_factors()


{
  # compare pred() against OEIS

  require Math::NumSeq::Abundant;
  require Math::NumSeq::OEIS::File;
  my $abundant = Math::NumSeq::Abundant->new (abundant_type => 'primitive');
  my $file = Math::NumSeq::OEIS::File->new (anum => 'A091191');
  foreach (1 .. 1000) {
    my ($f_i,$f_value) = $file->next;
    my ($a_i,$a_value) = $abundant->next;
    print "$a_i  $f_value $a_value\n";
  }
  print "\n";
  exit 0;
}
{
  require Math::NumSeq::Abundant;
  my $abundant = Math::NumSeq::Abundant->new (abundant_type => 'primitive');
  my $got = $abundant->pred(2828);
  print "got $got\n";

  my $sumdivisors = sumdivisors(2828);
  print "sumdivisors(2828)=",sumdivisors(2828),"   ",abundancy(2828),"\n";
  print "sumdivisors(28)=",sumdivisors(28),"   ",abundancy(28),"\n";
  exit 0;
}
BEGIN {
  require Math::NumSeq::OEIS::File;
  my $seq = Math::NumSeq::OEIS::File->new (anum => 'A000203');
  sub sumdivisors {
    my ($n) = @_;
    return $seq->ith($n);
  }
  sub abundancy {
    my ($n) = @_;
    return sumdivisors($n) / $n;
  }    
}
{
  require Math::NumSeq::Primes;
  my $primes = Math::NumSeq::Primes->new;
  my $prev = 0;
  foreach my $n (2 .. 1000) {
    my ($p,$k) = is_prime_power($n) or next;
    my $frac = pk_to_factor($p,$k);
    my $decr = ($frac < $prev ? '  ***decrease' : '');
    print "$n=$p^$k  $frac$decr\n";
    $prev = $frac;
  }
  exit 0;

  sub is_prime_power {
    my ($n) = @_;
    my @primes = prime_factors($n);
    my $k = scalar(@primes);
    while (@primes >= 2) {
      if ($primes[0] != $primes[1]) {
        return;
      }
      shift @primes;
    }
    return ($primes[0], $k);
  }

  sub pk_to_factor {
    my ($p,$k) = @_;
    return ($p**($k+1) - $p) / ($p**($k+1) - 1);
    # if ($k == 1) {
    #   return ($p-1)/($p**2 - 1);
    # } else {
    # }
  }
}

{
  require Math::NumSeq::Primes;
  my $primes = Math::NumSeq::Primes->new;
  foreach (1 .. 10) {
    my ($pi, $p) = $primes->next;
    foreach my $k (2 .. 6) {
      my $frac = pk_to_factor($p,$k);
      print "$p^$k  $frac\n";
    }
    print "\n";
  }
  exit 0;
}

{
  # factors() is slower, maybe due to arg checking overhead
  require Devel::TimeThis;

  require Math::NumSeq::Abundant;
  my $num = 100000;
  my $class = 'Math::NumSeq::Abundant';
  my ($i,$value);
  {
    my $seq = $class->new;
    my $t = Devel::TimeThis->new('next');
    foreach (1 .. $num) {
      ($i,$value) = $seq->next;
    }
  }
  print "i=$i value=$value\n";
  {
    my $seq = $class->new;
    my $t = Devel::TimeThis->new('pred');
    foreach (1 .. $value) {
      $seq->pred($_);
    }
  }
  exit 0;
}
