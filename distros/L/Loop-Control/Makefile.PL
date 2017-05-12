
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Loop::Control',
                       'DISTNAME' => 'Loop-Control',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'FIRST and NEXT functions for loops',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100861',
                       'PREREQ_PM' => {
                                        'Scalar::Util' => '0',
                                        'Scope::Upper' => '0',
                                        'English' => '0',
                                        'Exporter' => '0',
                                        'Carp' => '0',
                                        'Test::More' => '0.88',
                                        'Test::Differences' => '0',
                                        'File::Find' => '0',
                                        'File::Temp' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



