
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'HTTP::DAV::Xythos',
                       'DISTNAME' => 'HTTP-DAV-Xythos',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Jesse Thompson',
                       'BUILD_REQUIRES' => {
                                             'Test::More' => '0'
                                           },
                       'ABSTRACT' => 'Subclass of HTTP::DAV which adds support for Xythos Ticket authentication.',
                       'EXE_FILES' => [],
                       'VERSION' => '1.101180',
                       'PREREQ_PM' => {
                                        'HTTP::DAV' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



