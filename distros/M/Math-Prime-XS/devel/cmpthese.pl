#!/usr/bin/perl -w

use 5.004;
use Benchmark 'cmpthese';
use Math::Prime::XS ':all';

print "Math::Prime::XS version ",Math::Prime::XS->VERSION,"\n";

{
  my $number = 1_000_000;
  cmpthese(10, {
                 is_prime => sub { foreach (1 .. 1_000_000) { is_prime($_) } },
                });
  cmpthese(100, {
                 mod_primes => sub { mod_primes($number) },
                 sum_primes => sub { sum_primes($number) },
                 trial_primes => sub { trial_primes($number) },
                 sieve_primes => sub { sieve_primes($number) },
                });
}

{
  use constant NUM => 1000003; # a prime
  cmpthese(100000, {
                    is_prime => sub { is_prime(NUM) },
                    mod_primes => sub { mod_primes(NUM,NUM) },
                    # sum_primes => sub { sum_primes(NUM,NUM) },
                    # trial_primes => sub { trial_primes(NUM,NUM) },
                    # sieve_primes => sub { sieve_primes(NUM,NUM) },
                   });
}

exit 0;









# version 0.23 was
#
#                    Rate   mod_primes   sum_primes trial_primes sieve_primes
# mod_primes   6.39e-03/s           --        -100%        -100%        -100%
# sum_primes       8.10/s      126540%           --         -41%         -89%
# trial_primes     13.6/s      212979%          68%           --         -82%
# sieve_primes     74.6/s     1167064%         822%         448%           --
#
# and on Kevin's pc roughly
#
#                    Rate   mod_primes trial_primes   sum_primes sieve_primes
# mod_primes   1.26e-03/s           --        -100%        -100%        -100%
# trial_primes     3.12/s      247819%           --         -53%         -94%
# sum_primes       6.67/s      528793%         113%           --         -87%
# sieve_primes     50.0/s     3966600%        1500%         650%           --
