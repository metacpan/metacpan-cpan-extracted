# -*- mode: perl -*-

use strict;
use warnings;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   NAME                 => 'Math::BigInt::Random::OO',
   VERSION_FROM         => 'lib/Math/BigInt/Random/OO.pm',
   ABSTRACT_FROM        => 'lib/Math/BigInt/Random/OO.pm',
   AUTHOR               => 'Peter John Acklam <pjacklam@gmail.com>',

   # A hash of modules that are required to run Makefile.PL itself, but not to
   # run the distribution.

   'CONFIGURE_REQUIRES' => {
                            'ExtUtils::MakeMaker' => 6.58,
                           },

   # A hash of modules that are needed to build the module but not run it.

   'BUILD_REQUIRES'     => {},

   # A hash of modules that are needed to run the module.

   'PREREQ_PM'          => {
                            'Math::BigInt'        => 1.999814,
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
                url  => 'https://github.com/pjacklam/p5-Math-BigInt-Random-OO.git',
                web  => 'https://github.com/pjacklam/p5-Math-BigInt-Random-OO',
            },
        },
    },
  );
