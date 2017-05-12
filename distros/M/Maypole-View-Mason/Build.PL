use strict;

use Module::Build;

Module::Build->new
    ( module_name => 'Maypole::View::Mason',
      license     => 'perl',
      create_makefile_pl => 'passthrough',
      requires    => { 'Maypole'     => 2.06,
		       'HTML::Mason' => 1.20 },
    )->create_build_script;
