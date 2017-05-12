
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Hash::Inflator',
                       'DISTNAME' => 'Hash-Inflator',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>, Rick Measham <rickm@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Access hash entries through methods',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100820',
                       'PREREQ_PM' => {
                                        'Test::More' => '0.88',
                                        'Scalar::Util' => '0',
                                        'Test::Differences' => '0',
                                        'English' => '0',
                                        'File::Find' => '0',
                                        'File::Temp' => '0',
                                        'Carp' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



