# -*- mode: perl -*-

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs =
  (
   'NAME'               => 'Math::BigRat',
   'VERSION_FROM'       => 'lib/Math/BigRat.pm',
   'AUTHOR'             => 'Peter John Acklam <pjacklam@gmail.com>',
   'MIN_PERL_VERSION'   => 5.006,

   # A hash of modules that are required to run Makefile.PL itself, but not to
   # run the distribution.

   'CONFIGURE_REQUIRES' => {
                            'ExtUtils::MakeMaker' => 6.58,
                           },

   # A hash of modules that are needed to build the module but not run it.

   'BUILD_REQUIRES'     => {},

   # A hash of modules that are needed to run the module.

   'PREREQ_PM'          => {
                            'Math::BigInt'        => 1.999824,
                            'Math::Complex'       => 1.36,
                            'Scalar::Util'        => 0,
                            'Carp'                => 1.22,
                           },

   # A hash of modules that are needed to test the module but not run or build
   # it.

   'TEST_REQUIRES'      => {
                            'Test::More'          => 0.94,
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
                url  => 'https://github.com/pjacklam/p5-Math-BigRat.git',
                web  => 'https://github.com/pjacklam/p5-Math-BigRat',
            },
        },
    },
  );

# Install over the core version? (Cf. CPAN RT #119199 and #119225.)

$WriteMakefileArgs{INSTALLDIRS} = 'perl'
  if $] >= 5.008 && $] < 5.012;

WriteMakefile(%WriteMakefileArgs);
