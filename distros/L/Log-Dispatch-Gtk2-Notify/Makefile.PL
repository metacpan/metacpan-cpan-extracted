
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Log::Dispatch::Gtk2::Notify',
                       'DISTNAME' => 'Log-Dispatch-Gtk2-Notify',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Florian Ragwitz <rafl@debian.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'send log messages to a desktop notification daemon',
                       'EXE_FILES' => [],
                       'VERSION' => '0.02',
                       'PREREQ_PM' => {
                                        'MooseX::Types::Moose' => '0',
                                        'namespace::clean' => '0',
                                        'MooseX::Types' => '0',
                                        'Gtk2::Notify' => '0',
                                        'Log::Dispatch' => '0',
                                        'File::Basename' => '0',
                                        'Gtk2' => '0',
                                        'Moose' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



