use strict;

use Module::Build;

my $build =
    Module::Build->new( module_name => 'Log::Dispatch::Email::EmailSend',
                        license     => 'perl',
                        requires    => { 'Email::Send'            => 2.0,
                                         'Email::Simple::Creator' => 0,
                                         'Log::Dispatch'          => 2.0,
                                         'Params::Validate'       => 0,
                                       },
                        build_requires => { 'Email::Send::Test' => 0,
                                            'Module::Build'     => 0,
                                          },
                        sign        => 1,
                        create_makefile_pl => 'passthrough',
                      );

$build->create_build_script;
