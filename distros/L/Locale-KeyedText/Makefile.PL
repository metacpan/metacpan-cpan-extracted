#!perl
use 5.008001;
use utf8;
use strict;
use warnings;

warn q{
---------------------------------------------------------------------------
  Please ignore any test failures when installing the 'only' module, which
  this distribution depends on; 'only' still works correctly for my needs.

  You can also ignore any warnings during installation about the use of
  "=encoding utf8" in the pod documentation.

  Continuing in 3 seconds...
---------------------------------------------------------------------------
};
sleep 3;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Locale::KeyedText',
    'VERSION_FROM' => 'lib/Locale/KeyedText.pm', # finds $VERSION
    'ABSTRACT' => 'Refer to user messages in programs by keys',
    'AUTHOR' => 'Darren R. Duncan <perl@DarrenDuncan.net>',
#    'LICENSE' => 'lgpl',
    'PREREQ_PM' => {
        # These mainly add features to Perl 5 that are built-in to Perl 6.
        'version' => 0.57,
        'only' => 0,
        'Readonly' => 1.03,
        'Class::Std' => 0.000008,
        'Class::Std::Utils' => 0.000002,
        'Scalar::Util' => 0,
        # These are used in both the Perl 5 and Perl 6 versions.
        #   (None yet, if ever.)
        # These mainly are for the test suite.
        'Test::More' => 0,
    },
);

1; # Magic true value required at end of a reuseable file's code.
