use strict;

use Module::Build;

Module::Build->new
    ( module_name => 'Maypole::Plugin::Upload',
      license     => 'perl',
      create_makefile_pl => 'passthrough',
      requires    => { 'Maypole' => 2.0 },
    )->create_build_script;
