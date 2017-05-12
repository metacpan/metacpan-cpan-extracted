#!perl

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'               => 'Math::Roman',
   'VERSION_FROM'       => 'lib/Math/Roman.pm', # finds $VERSION
   'PREREQ_PM'          => {
                            #'ExtUtils::MakeMaker' => 6.58,
                            'Test'                => 0,
                            'Math::BigInt'        => 1.35,
                           },
   'LIBS'               => [''], # e.g., '-lm'
   'DEFINE'             => '',   # e.g., '-DHAVE_SOMETHING'
   'INC'                => '',   # e.g., '-I/usr/include/other'
  );
