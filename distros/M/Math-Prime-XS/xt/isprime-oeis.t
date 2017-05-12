#!/usr/bin/perl

# run is_prime() against http://oeis.org/A000040/a000040.txt expected to be
# in ~/OEIS/a000040.txt locally.

use strict;
use warnings;

use Math::Prime::XS 'is_prime';
use Test::More tests => 1;

use File::Spec;
use File::HomeDir;
my $filename = File::Spec->catfile (File::HomeDir->my_home,
                                    'OEIS',
                                    'a000040.txt');
open IN, "< $filename" or die;
my $count = 0;
my $count_primes = 0;
my $good = 1;
my $upto = 0;
my $prime;
while (<IN> =~ /[0-9]+\s+([0-9]+)/) {
  $count_primes++;
  $prime = $1;

  while ($upto < $prime) {
    $count++;
    if (is_prime($upto)) {
      diag "oops is_prime($upto) should be false";
      $good = 0;
    }
    $upto++;
  }

  $count++;
  unless (is_prime($upto)) {
    diag "oops is_prime($upto) should be true";
    $good = 0;
  }
  $upto++;
}

diag "tested 0 to $count, with $count_primes primes up to $prime";

ok ($good);
exit 0;
