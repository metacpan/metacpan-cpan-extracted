#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

#printf "Your OS is [%s]!\n---\n", $Config::Config{'osname'};  ### for testing purpose only

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
   'PREREQ_PM'          => {
                            #'ExtUtils::MakeMaker' => 6.58,
                            'XSLoader'            => 0.02,
                            'Test::More'          => 0.82,
                            'Math::BigInt'        => 1.999808,
                           },
   'LICENSE'            => 'perl_5',
   'LIBS'               => ['-lgmp'],   # e.g., '-lm'
   'DEFINE'             => '',          # e.g., '-DHAVE_SOMETHING'
   'INC'                => '',          # e.g., '-I/usr/include/other'
   'SIGN'               => 1,
  );
