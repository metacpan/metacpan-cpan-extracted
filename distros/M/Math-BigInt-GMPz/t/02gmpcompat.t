# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

#use Math::GMPz 0.36 qw< :mpz >;
BEGIN { use_ok("Math::GMPz", 0.36, ":mpz") }

# We need GMP 5.1.0 or newer for Rmpz_2fac_ui().

# It might be that Math::GMPz was built with a newer version of GMP than the
# one that is currently available. Checking Math::GMPz::gmp_v() won't help,
# since it seems to return the version of GMP used when Math::GMPz was built,
# not the version of GMP that is currently available.

# If Rmpz_2fac_ui() is not implemented, Math::GMPz dies with the message:
# "Rmpz_2fac_ui not implemented - gmp-5.1.0 (or later) is needed"

eval { my $x = Rmpz_init(); Rmpz_2fac_ui($x, 0); };
ok(! $@, "gmp-5.1.0 (or later) is available") or diag <<"EOF"
  The version of the GMP library that is used by Math::GMPz is too old.
EOF
