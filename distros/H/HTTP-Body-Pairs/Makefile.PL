
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'HTTP::Body::Pairs',
                       'DISTNAME' => 'HTTP-Body-Pairs',
                       'AUTHOR' => 'Paul Driver',
                       'ABSTRACT' => 'methods for getting body params in the order they were sent',
                       'EXE_FILES' => [],
                       'VERSION' => '0.3',
                       'LICENSE' => 'perl',
                       'PREREQ_PM' => {
                                        'ExtUtils::MakeMaker' => '6.11',
                                        'HTTP::Body' => '0'
                                      }
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



