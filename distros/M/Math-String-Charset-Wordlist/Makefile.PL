#!perl

use strict;

use ExtUtils::MakeMaker;

WriteMakefile
  (
   'NAME'               => 'Math::String::Charset::Wordlist',
   'VERSION_FROM'       => 'lib/Math/String/Charset/Wordlist.pm',
   'AUTHOR'             => 'Peter John Acklam <pjacklam@gmail.com>',
   'MIN_PERL_VERSION'   => 5.008003,
   'PREREQ_PM'          => {
                            #'ExtUtils::MakeMaker' => 6.58,
                            'Test::More'        => 0.47,
                            'Math::BigInt'      => 1.74,
                            'Math::String'      => 1.22,
                           },
   'LICENSE'            => 'perl_5',
   'LIBS'               => [''], # e.g., '-lm'
   'DEFINE'             => '',   # e.g., '-DHAVE_SOMETHING'
   'INC'                => '',   # e.g., '-I/usr/include/other'
   'SIGN'               => 1,
  );
