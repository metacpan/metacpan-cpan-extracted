#!perl

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
                            'Math::BigInt'        => 1.999819,
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

# See if we have the required version of the GMP library.
#
# Even if the version of Math::GMPz is recent enough, the tests for the double
# factorial sometimes fail. I suspect this is because the GMP library is too
# old. The double factorial function Rmpz_2fac_ui() was introduced in GMP
# version 5.1.0.

my $gmp_v_str_req = '5.1.0';
my $gmp_v_flt_req = 5.001000;

eval { require Math::GMPz; };
unless ($@) {
    my $gmp_v_str = Math::GMPz::gmp_v();

    my @parts = split /\./, $gmp_v_str;
    push @parts, (0) x (3 - @parts);
    my $gmp_v_flt =
      sprintf '%.6f', $parts[0] + 1e-3 * $parts[1] + 1e-6 * $parts[2];

    if ($gmp_v_flt < $gmp_v_flt_req) {
        warn "Warning: prerequisite GMP library $gmp_v_str_req not found.",
          " We have $gmp_v_str_req.\n"
    }
}
