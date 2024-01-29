# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

#use Math::GMPz 0.36 qw< :mpz >;
BEGIN { use_ok("Math::GMPz", 0.36, ":mpz") }

# We need GMP 5.1.0 or newer for Rmpz_2fac_ui(). If Rmpz_2fac_ui() is not
# implemented, Math::GMPz dies with the message:
# "Rmpz_2fac_ui not implemented - gmp-5.1.0 (or later) is needed"

my $gmp_v = Math::GMPz::gmp_v();
my @gmp_v = split /\./, $gmp_v;
my $gmp_v_int = 1e6 * $gmp_v[0] + 1e3 * $gmp_v[1] + $gmp_v[0];
ok($gmp_v_int >= 5_100_000,
   "GMP library is recent enough (we have $gmp_v, we need 5.1.0 or later)");
