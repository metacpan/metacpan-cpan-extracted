use strict;

use Module::Build;

my $build =
    Module::Build->new( module_name => 'Exception::Class::Nested',
                        license     => 'perl',
                        requires    => { 'Exception::Class' => 1.00,
                                       },
                        sign        => 0,
                        create_makefile_pl => 'traditional',
                      );

$build->create_build_script;
