#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (
   'NAME'               => 'Math-BigInt-BitVect',
   'VERSION_FROM'       => 'lib/Math/BigInt/BitVect.pm',
   'AUTHOR'             => 'Peter John Acklam <pjacklam@gmail.com>',
   'PREREQ_PM'          => {
                            #'ExtUtils::MakeMaker' => 6.58,
                            'Test::More'          => 0.88,
                            'Math::BigInt'        => 1.999812,
                            'Bit::Vector'         => 0,
                           },
   'LICENSE'            => 'perl_5',
   'LIBS'               => [''],          # e.g., '-lm'
   'DEFINE'             => '',            # e.g., '-DHAVE_SOMETHING'
   'INC'                => '',            # e.g., '-I/usr/include/other'
   'SIGN'               => 1,
  );
