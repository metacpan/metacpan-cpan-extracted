#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true false);

use Math::Prime::XS ':all';
use Test::More tests => 29;

diag "perl version ",$];

local $" = ',';

my $number = 100;
my @range  = (30, 70);
my @prime  = (13) x 2;

my @expected_all_primes = (
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29,
    31, 37, 41, 43, 47, 53, 59, 61, 67,
    71, 73, 79, 83, 89, 97,
);
my @expected_range_primes = (
    31, 37, 41, 43, 47, 53, 59, 61, 67,
);
my $expected_prime = $prime[0];

my @got_primes;
foreach my $num (0 .. $number) {
    push @got_primes, $num if is_prime($num);
}
is_deeply(\@got_primes, \@expected_all_primes, "is_prime() [0-$number]");
ok (! is_prime(0xFFFF_FFFF), "is_prime() on 0xFFFF_FFFF");
ok (! eval { is_prime(-1); 1 }, "is_prime() croak on -1");
ok (! eval { is_prime(2**256); 1 }, "is_prime() croak on 2**256");
my $infinity;
SKIP: {
  require POSIX;
  my $inf = POSIX::DBL_MAX() * POSIX::DBL_MAX();
  diag "inf is: ",$inf;
  $inf > POSIX::DBL_MAX()
    or skip "no floating point infinity, it seems", 2;
  $infinity = $inf;
  ok (! eval { is_prime($inf); 1 }, "is_prime() croak on +infinity");
  ok (! eval { is_prime(-$inf); 1 }, "is_prime() croak on -infinity");
}
SKIP: {
  require POSIX;
  my $nan = (defined $infinity && $infinity / $infinity);
  diag "nan is: ",$nan;
  $nan != $nan
    or skip "no floating point nan, it seems", 2;
  my $neg_nan = - $nan;
  diag "neg nan is: ",$neg_nan;
  ok (! eval { is_prime($nan); 1 }, "is_prime() croak on nan");
  ok (! eval { is_prime($neg_nan); 1 }, "is_prime() croak on -nan");
}

is_deeply([primes($number)],       \@expected_all_primes, "primes($number)",     );
is_deeply([mod_primes($number)],   \@expected_all_primes, "mod_primes($number)"  );
is_deeply([sieve_primes($number)], \@expected_all_primes, "sieve_primes($number)");
is_deeply([sum_primes($number)],   \@expected_all_primes, "sum_primes($number)"  );
is_deeply([trial_primes($number)], \@expected_all_primes, "trial_primes($number)");
is_deeply([count_primes($number)], [scalar(@expected_all_primes)],
          "count_primes($number)");

is_deeply([primes(@range)],       \@expected_range_primes, "primes(@range)"      );
is_deeply([mod_primes(@range)],   \@expected_range_primes, "mod_primes(@range)"  );
is_deeply([sieve_primes(@range)], \@expected_range_primes, "sieve_primes(@range)");
is_deeply([sum_primes(@range)],   \@expected_range_primes, "sum_primes(@range)"  );
is_deeply([trial_primes(@range)], \@expected_range_primes, "trial_primes(@range)");
is_deeply([count_primes(@range)], [scalar(@expected_range_primes)],
          "count_primes($number)");

is(primes(@prime),       $expected_prime, "primes(@prime)"      );
is(mod_primes(@prime),   $expected_prime, "mod_primes(@prime)"  );
is(sieve_primes(@prime), $expected_prime, "sieve_primes(@prime)");
is(sum_primes(@prime),   $expected_prime, "sum_primes(@prime)"  );
is(trial_primes(@prime), $expected_prime, "trial_primes(@prime)");

{
    # rt #62632
    my $number = 2000000;
    my $prime  = 1928099;

    my $found = false;
    foreach my $p (sieve_primes($number)) {
        if ($p == $prime) {
            $found = true;
            last;
        }
    }
    ok($found, "sieve_primes($number) - prime $prime not returned");
}

# 0xFFFF_FFFF = 2^32-1 and 0xFF...FF = 2^64-1 are both divisible by 3 so
# mod_primes() is fast on them.
#
# On a 32-bit system 2^64-1 is silently truncated to 2^32-1 in usual Perl
# fashion, but check longsize so as not to attempt a value too big to
# handle.
#
{
  my $n = 2**32-1;
  my @got = mod_primes($n,$n);
  is_deeply(\@got, [], "mod_primes() no infinite loop trying $n");
}
SKIP: {
  require Config;
  unless ($Config::Config{'longsize'} >= 8) {
    skip "longsize only $Config::Config{'longsize'}, don't try 2**64-1", 2;
  }
  my $n = 2**64-1;
  my @got = mod_primes($n,$n);
  is_deeply(\@got, [], "mod_primes() no infinite loop trying $n");
  ok (! is_prime($n), "is_prime() on $n");
}
