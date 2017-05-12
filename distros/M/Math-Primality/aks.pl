#!/usr/bin/perl

use strict;
use warnings;

{
  package polynomial;

package main;

use Math::GMPz qw/:mpz/;
use Data::Dumper;

if (scalar(@ARGV) != 1) {
  print "Usage: aks.pl <number to test>\n";
  exit
}

my $n;
print "Math::GMPz version: $Math::GMPz::VERSION\n";
eval {
  $n = Math::GMPz->new($ARGV[0]);
  1;
} or do {
  print "Error converting ", $ARGV[0], "to a number\n";
  exit;
};
print "Running AKS with number $n\n";

if(Rmpz_perfect_power_p($n)) {
  print "$n is a perfect power.\n";
  exit;
}

my $r = Math::GMPz->new(2);
my $logn = Rmpz_sizeinbase($n, 2);
my $limit = Math::GMPz->new($logn * $logn);
Rmpz_mul_ui($limit, $limit, 4);

# Witness search

OUTERLOOP: while (Rmpz_cmp($r, $n) == -1) {
  if(Rmpz_divisible_p($n, $r)) {
    print "$n is divisible by $r\n";
    exit;
  }

  if(Rmpz_probab_prime_p($n, 5)) {
    my $i = Math::GMPz->new(1);

    INNERLOOP: for ( ; Rmpz_cmp($n, $limit) <= 0; Rmpz_add_ui($i, $i, 1)) {
      my $res = Math::GMPz->new(0);
      Rmpz_powm($res, $n, $i, $r);
      if (Rmpz_cmp_ui($res, 1) == 0) {
        last OUTERLOOP;
      }
    }

  }
  Rmpz_add_ui($r, $r, 1);
}
if (Rmpz_cmp($r, $n) == 0) {
  print "Found $n is prime while checking for r\n";
  exit;
}

# Polynomial check
my $a;
my $sqrtr = Math::GMPz->new(0);

Rmpz_sqrt($sqrtr, $r);
my $polylimit = Math::GMPz->new(0);
Rmpz_add_ui($polylimit, $sqrtr, 1);
Rmpz_mul_ui($polylimit, $polylimit, $logn);
Rmpz_mul_ui($polylimit, $polylimit, 2);

my $intr = Rmpz_get_ui($r);

for($a = 1; Rmpz_cmp_ui($polylimit, $a) <= 0; $a++) {
  print "Checking at $a\n";
  my $final_size = Math::GMPz->new(0);
  Rmpz_mod($final_size, $n, $r);
  my $compare = polynomial->new(Rmpz_get_ui($final_size));
  $compare->setCoef(1, Rmpz_get_ui($final_size));
  $compare->setCoef($a, 0);
  my $res = polynomial->new($intr);
  my $base = polynomial->new(1);
  $base->setCoef($a, 0);
  $base->setCoef(1, 1);

  mpz_poly_mod_power($res, $base, $n, $n, $intr);

  if($res->isEqual($compare)) {
    print "Found not prime at $a\n";
    exit;
  }
}
print "Is prime\n";
