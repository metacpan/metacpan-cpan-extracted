#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

if (($Config::Config{'osname'} eq 'darwin')
    && !(join (' ', @ARGV) =~ /LDDLFLAGS/)) {
    ### reads pre-existing LDDLFLAGS for a darwin system as defined in
    ###  /System/Library/Perl/x.x.x/darwin-thread-multi-2level/Config.pm
    ###  where x.x.x is the perl version, which is 5.8.1 for MacOS X 10.3,
    ###  and appends ' -read_only_relocs suppress'
    ### default behavior if LDDLFLAGS is defined
    push @ARGV, sprintf("LDDLFLAGS=%s -read_only_relocs suppress",
                        $Config::Config{'lddlflags'});
}

WriteMakefile
  (
   'NAME'               => 'Math::BigInt::GMP',
   'VERSION_FROM'       => 'lib/Math/BigInt/GMP.pm',
   'AUTHOR'             => 'Peter John Acklam <pjacklam@gmail.com>',
   'MIN_PERL_VERSION'   => 5.006001,

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
                            'Math::BigInt'        => 1.999817,
                            'XSLoader'            => 0.02,
                           },

   # A hash of modules that are needed to test the module but not run or build
   # it.

   'TEST_REQUIRES'      => {
                            'Test::More'          => 0.82,
                           },

   'LICENSE'            => 'perl_5',
   'LIBS'               => ['-lgmp'],   # e.g., '-lm'
   'DEFINE'             => '',          # e.g., '-DHAVE_SOMETHING'
   'INC'                => '',          # e.g., '-I/usr/include/other'
   'SIGN'               => 1,

   'META_MERGE'         => {
       'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/pjacklam/p5-Math-BigInt-GMP.git',
                web  => 'https://github.com/pjacklam/p5-Math-BigInt-GMP',
            },
        },
    },
  );
