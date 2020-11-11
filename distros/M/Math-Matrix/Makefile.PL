#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs =
  (
   'NAME'               => 'Math::Matrix',
   'VERSION_FROM'       => 'lib/Math/Matrix.pm',
   'AUTHOR'             => 'Peter John Acklam <pjacklam@gmail.com>',
   'dist'               => { SUFFIX => 'gz', COMPRESS => 'gzip -f' },
   'clean'              => {'FILES' => '*~'},

   # A hash of modules that are required to run Makefile.PL itself, but not to
   # run the distribution.

   'CONFIGURE_REQUIRES' => {
                            'ExtUtils::MakeMaker' => 6.58,
                           },

   # A hash of modules that are needed to build the module but not run it.

   'BUILD_REQUIRES'     => {},

   # A hash of modules that are needed to run the module.

   'PREREQ_PM'          => {
                            'Scalar::Util'        => 1.00,
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
                url  => 'https://github.com/pjacklam/p5-Math-Matrix.git',
                web  => 'https://github.com/pjacklam/p5-Math-Matrix',
            },
        },
    },
  );

WriteMakefile(%WriteMakefileArgs);
