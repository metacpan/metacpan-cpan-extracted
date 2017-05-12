
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Log::Log4perl::Appender::Stomp',
                       'DISTNAME' => 'Log-Log4perl-Appender-Stomp',
                       'AUTHOR' => 'Adam Flott <adam@npjh.com>',
                       'ABSTRACT' => 'Log messages via STOMP',
                       'EXE_FILES' => [],
                       'VERSION' => '1.000',
                       'LICENSE' => 'perl',
                       'PREREQ_PM' => {
                                        'ExtUtils::MakeMaker' => '6.11',
                                        'Net::Stomp' => '0',
                                        'Log::Log4perl' => '0'
                                      }
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



