# -*- mode: perl; -*-

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (
   'NAME'               => 'Math::BigInt::GMPz',
   'VERSION_FROM'       => 'lib/Math/BigInt/GMPz.pm',
   'AUTHOR'             => 'Peter John Acklam <pjacklam@gmail.com>',
   'MIN_PERL_VERSION'   => 5.006002,

   # A hash of modules that are required to run Makefile.PL itself, but not to
   # run the distribution.

   'CONFIGURE_REQUIRES' => {
                            'ExtUtils::MakeMaker' => 6.58,
                           },

   # A hash of modules that are needed to build the module but not run it.

   'BUILD_REQUIRES'     => {},

   # A hash of modules that are needed to run the module.

   'PREREQ_PM'          => {
                            'Math::BigInt'        => 1.999838,
                            'Math::GMPz'          => 0.36,
                           },

   # A hash of modules that are needed to test the module but not run or build
   # it.

   'TEST_REQUIRES'      => {
                            'Test::More'          => 0.82,
                           },

   'LICENSE'            => 'perl_5',
   'LIBS'               => [''],        # e.g., '-lm'
   'DEFINE'             => '',          # e.g., '-DHAVE_SOMETHING'
   'INC'                => '',          # e.g., '-I/usr/include/other'
   'SIGN'               => 1,

   'META_MERGE'         => {
       'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/pjacklam/p5-Math-BigInt-GMPz.git',
                web  => 'https://github.com/pjacklam/p5-Math-BigInt-GMPz',
            },
        },
    },
  );

###############################################################################
# It might be that Math::GMPz was built with an newer version of GMP than the
# one that is currently available. Checking Math::GMPz::gmp_v() won't help,
# since it returns the version of GMP used when Math::GMPz was built, not the
# version of GMP that is currently available.

use Math::GMPz 0.36 qw< :mpz >;

eval { my $x = Rmpz_init(); Rmpz_2fac_ui($x, 0); };

# If Rmpz_2fac_ui() is not implemented, Math::GMPz dies with the message:
# "Rmpz_2fac_ui not implemented - gmp-5.1.0 (or later) is needed"

die "gmp-5.1.0 (or later) is needed" if $@;
