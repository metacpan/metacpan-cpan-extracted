#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
  (
   NAME          => 'Geo::Ellipsoid',
   AUTHOR        => 'Peter John Acklam <pjacklam@gmail.com>',

   VERSION_FROM  => 'lib/Geo/Ellipsoid.pm',
   ABSTRACT_FROM => 'lib/Geo/Ellipsoid.pm',

   # A hash of modules that are required to run Makefile.PL itself, but not to
   # run the distribution.

   'CONFIGURE_REQUIRES' => {
                            'ExtUtils::MakeMaker' => 6.58,
                           },

   # A hash of modules that are needed to build the module but not run it.

   'BUILD_REQUIRES'     => {
                           },

   # A hash of modules that are needed to run the module.

   'PREREQ_PM'          => {
                            'Scalar::Util'        => 1.19,
                            'Math::Trig'          => 1.23,
                            'Carp'                => 1.22,
                           },

   # A hash of modules that are needed to test the module but not run or build
   # it.

   'TEST_REQUIRES'      => {
                            'Test::More'          => 0.47,
                            'Test::Number::Delta' => 0.13,
                           },

   # Repository information.

   'META_MERGE'         => {
       'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/pjacklam/p5-Geo-Ellipsoid.git',
                web  => 'https://github.com/pjacklam/p5-Geo-Ellipsoid',
            },
        },
    },

  );
