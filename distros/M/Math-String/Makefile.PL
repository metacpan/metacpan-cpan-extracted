#!perl

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'               => 'Math::String',
   'VERSION_FROM'       => 'lib/Math/String.pm',
   'AUTHOR'             => 'Peter John Acklam <pjacklam@gmail.com>',
   'MIN_PERL_VERSION'   => 5.008003,
   'PREREQ_PM'          => {
                            #'ExtUtils::MakeMaker' => 6.58,
                            'Test::More'        => 0.47,
                            'Math::BigInt'      => 1.999802,
                           },
   'LICENSE'            => 'gpl',
   'LIBS'               => [''], # e.g., '-lm'
   'DEFINE'             => '',   # e.g., '-DHAVE_SOMETHING'
   'INC'                => '',   # e.g., '-I/usr/include/other'
   'SIGN'               => 1,
  );
