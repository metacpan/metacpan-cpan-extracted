# -*- mode: perl; -*-

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs =
  (
   'NAME'               => 'Math::BigInt::FastCalc',
   'VERSION_FROM'       => 'lib/Math/BigInt/FastCalc.pm',
   'AUTHOR'             => 'Peter John Acklam <pjacklam@gmail.com>',
   'MIN_PERL_VERSION'   => 5.006001,

   # A hash of modules that are required to run Makefile.PL itself, but not to
   # run the distribution.

   'CONFIGURE_REQUIRES' => {
                            'ExtUtils::MakeMaker' => 6.58,
                           },

   # A hash of modules that are needed to build the module but not run it.

   'BUILD_REQUIRES'     => {},

   # A hash of modules that are needed to run the module.

   'PREREQ_PM'          => {
                            'Math::BigInt'        => 1.999840,
                            'Carp'                => 1.22,
                            'XSLoader'            => 0,
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
                url  => 'https://github.com/pjacklam/p5-Math-BigInt-FastCalc.git',
                web  => 'https://github.com/pjacklam/p5-Math-BigInt-FastCalc',
            },
        },
    },
  );

# Install over the core version? (Cf. CPAN RT #119199 and #119225.)

$WriteMakefileArgs{INSTALLDIRS} = 'perl'
  if $] >= 5.009003 && $] < 5.012;

WriteMakefile(%WriteMakefileArgs);
