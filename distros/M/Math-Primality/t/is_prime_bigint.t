#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Math::Primality qw/:all/;
use bigint;

plan;

ok(is_prime(18446744073709551629), 'is_prime() works with bigint');
ok(is_pseudoprime(18446744073709551629), 'is_pseudoprime() works with bigint');
ok(is_pseudoprime(18446744073709551629, 3), 'is_pseudoprime(x,3) works with bigint');

ok(is_strong_lucas_pseudoprime(18446744073709551629), 'is_strong_lucas_pseudoprime() works with bigint');

ok(is_strong_pseudoprime(18446744073709551629), 'is_strong_pseudoprime() works with bigint');


ok(next_prime(18446744073709551629), 'next_prime works with bigint');
ok(prev_prime(18446744073709551629), 'prev_prime works with bigint');

ok(prime_count(Math::BigInt->new(10)), 'prime_count works with Math::BigInt objects');

done_testing;
