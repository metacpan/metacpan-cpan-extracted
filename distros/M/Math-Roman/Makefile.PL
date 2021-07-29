# -*- mode: perl -*-

use strict;
use warnings;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'               => 'Math::Roman',
   'VERSION_FROM'       => 'lib/Math/Roman.pm', # finds $VERSION

   # A hash of modules that are required to run Makefile.PL itself, but not to
   # run the distribution.

   'CONFIGURE_REQUIRES' => {
                            'ExtUtils::MakeMaker' => 6.58,
                           },

   # A hash of modules that are needed to build the module but not run it.

   'BUILD_REQUIRES'     => {},

   # A hash of modules that are needed to run the module.

   'PREREQ_PM'          => {
                            'Math::BigInt'        => 1.2,
                           },

   # A hash of modules that are needed to test the module but not run or build
   # it.

   'TEST_REQUIRES'      => {
                            'Test::More'          => 0.47,
                           },

   'LIBS'               => [''], # e.g., '-lm'
   'DEFINE'             => '',   # e.g., '-DHAVE_SOMETHING'
   'INC'                => '',   # e.g., '-I/usr/include/other'

   'META_MERGE'         => {
       'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/pjacklam/p5-Math-Roman.git',
                web  => 'https://github.com/pjacklam/p5-Math-Roman',
            },
        },
    },
  );
