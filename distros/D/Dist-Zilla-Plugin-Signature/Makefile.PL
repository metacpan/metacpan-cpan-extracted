
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Dist::Zilla::Plugin::Signature',
                       'DISTNAME' => 'Dist-Zilla-Plugin-Signature',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Graham Barr',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'sign releases with Module::Signature',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100930',
                       'PREREQ_PM' => {
                                        'Module::Signature' => '0',
                                        'Dist::Zilla' => '2.100921',
                                        'File::chdir' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



