use strict;
use Module::Build;

Module::Build->new(
    module_name => "Games::Tetris",
    license     => 'perl',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Class::Accessor::Fast' => 0,
    },
    create_makefile_pl => 'passthrough',
   )
  ->create_build_script;
