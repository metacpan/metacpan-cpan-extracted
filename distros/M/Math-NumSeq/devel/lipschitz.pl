#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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
use List::MoreUtils;
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099
use Math::Factor::XS 0.39 'prime_factors'; # version 0.39 for prime_factors()

{
  # distinct primes
  foreach my $i (2 .. 20) {
    my @primes = prime_factors($i);
    @primes = List::MoreUtils::uniq(@primes);
    my $dist = 1;
    foreach (@primes) { $dist *= $_ }
    print "$dist,";
  }
  print "\n";
  exit 0;
}

{
  # The development of prime number theory: from Euclid to Hardy and Littlewood
  #
  # Lipschitz 1890 Bemerkung zu dem aufsatze: Untersuchungen der
  # Eigenschaften einer Gattung von unendlichen Reihen J. Reine Agnew Math
  # 106 27-29
  # http://resolver.sub.uni-goettingen.de/purl?PPN243919689_0106/dmdlog6
  # http://www.digizeitschriften.de/index.php?id=resolveppn&PPN=PPN243919689_0106&DMDID=dmdlog6
  #
  # require Math::NumSeq::LipschitzClass;
  # my $seq = Math::NumSeq::LipschitzClass->new;

  my @P = (undef, { 2 => 1 });
  my @I = (undef, { 2 => 1 });
  my %I_left;
  @I_left{3..1000} = (); # hash slice

  foreach my $i (1 .. 10) {
    my $Pstr = join(',',sort {$a<=>$b} keys %{$P[$i]});
    print "P$i: $Pstr\n";

    my $Istr = join(',',sort {$a<=>$b} keys %{$I[$i]});
    print "I$i: $Istr\n";

    foreach my $v (keys %{$I[$i]}) {
      if (is_prime($v+1)) {
        $P[$i+1]->{$v+1} = 1;
      }
    }

    foreach my $v (keys %I_left) {
      if (all_factor_in_Ps($i,$v)) {
        $I[$i+1]->{$v} = 1;
        delete $I_left{$v};
      }
    }
  }

  sub all_factor_in_Ps {
    my ($i, $v) = @_;
    foreach my $factor (prime_factors($v)) {
      if (! factor_in_Ps($i, $factor)) {
        return 0;
      }
    }
    return 1;
  }

  sub factor_in_Ps {
    my ($i, $factor) = @_;
    foreach my $j (1 .. $i) {
      if ($P[$j]->{$factor}) {
        return 1;
      }
    }
    return 0;
  }
  exit 0;
}

{
  # Lipschitz by seq
  require Math::NumSeq::LipschitzClass;
  my $seq = Math::NumSeq::LipschitzClass->new;
  my @P;
  my @I;
  foreach (1 .. 1000) {
    my ($i, $value) = $seq->next;
    push @{$I[$value]}, $i;
  }
  $seq = Math::NumSeq::LipschitzClass->new (lipschitz_type => 'P');
  foreach (1 .. 1000) {
    my ($i, $value) = $seq->next;
    if ($value) {
      push @{$P[$value]}, $i;
    }
  }

  foreach my $i (1 .. 10) {
    my $Pstr = join(',', @{$P[$i]//[]});
    print "P$i: $Pstr\n";

    my $Istr = join(',', @{$I[$i]//[]});
    print "I$i: $Istr\n";
  }
  exit 0;
}

{
  # Lipschitz cf ErdosSelfridge
  require Math::NumSeq::LipschitzClass;
  require Math::NumSeq::ErdosSelfridgeClass;
  require Math::NumSeq::Primes;
  my $primes = Math::NumSeq::Primes->new;
  my $lips = Math::NumSeq::LipschitzClass->new(lipschitz_type=>'P');
  my $erd = Math::NumSeq::ErdosSelfridgeClass->new (p_or_m=>'-');

  for (1 .. 20) {
    my (undef, $prime) = $primes->next;
    my $l = $lips->ith($prime);
    my $e = $erd->ith($prime);
    print "$prime  $l $e\n";
  }
  exit 0;
}
