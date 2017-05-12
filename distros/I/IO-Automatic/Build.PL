use strict;
use Module::Build;

Module::Build->new(
    module_name => "IO::Automatic",
    license     => 'perl',
    requires    => {
        'Test::More'    => 0,
        'Module::Build' => 0,
        'IO::File'      => 0,
        'IO::Zlib'      => 0,
        'IO::Scalar'    => 0,
    },
    create_makefile_pl => 'passthrough',
   )
  ->create_build_script;
