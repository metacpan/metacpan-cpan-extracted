
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Hook::Modular',
                       'DISTNAME' => 'Hook-Modular',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>, Tatsuhiko Miyagawa <miyagawa@bulknews.net>',
                       'BUILD_REQUIRES' => {
                                             'Test::More' => '0.94',
                                             'English' => '0',
                                             'FindBin' => '0',
                                             'File::Find' => '0'
                                           },
                       'ABSTRACT' => 'Making pluggable applications easy',
                       'EXE_FILES' => [],
                       'VERSION' => '1.101050',
                       'PREREQ_PM' => {
                                        'Scalar::Util' => '0',
                                        'UNIVERSAL' => '0',
                                        'YAML' => '0',
                                        'File::Spec' => '0',
                                        'Storable' => '0',
                                        'Class::Accessor::Fast' => '0',
                                        'Encode' => '0',
                                        'List::Util' => '0',
                                        'File::Path' => '0',
                                        'File::Find::Rule' => '0',
                                        'File::Copy' => '0',
                                        'Module::Pluggable' => '0',
                                        'Attribute::Handlers' => '0',
                                        'parent' => '0',
                                        'File::HomeDir' => '0',
                                        'Data::Dumper' => '0',
                                        'constant' => '0',
                                        'Exporter' => '0',
                                        'Carp' => '0',
                                        'Term::Encoding' => '0',
                                        'MIME::Base64' => '0',
                                        'File::Temp' => '0',
                                        'File::Basename' => '0',
                                        'UNIVERSAL::require' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



