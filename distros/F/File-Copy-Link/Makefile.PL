# Created by Build.PL
use 5.006;
use strict;
use ExtUtils::MakeMaker;
my $args = {
          'NAME' => 'File::Copy::Link',
          'AUTHOR' => 'Robin Barker <rmbarker@cpan.org>',
          'ABSTRACT_FROM' => 'lib/File/Copy/Link.pm',
          'PL_FILES' => {},
          'EXE_FILES' => [
                           'copylink'
                         ],
          'PREREQ_PM' => {
                           'File::Spec' => 0,
                           'File::Copy' => 0
                         },
          'VERSION' => '0.140'
        };

WriteMakefile( %$args );
