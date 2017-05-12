use strict;

use Module::Build;

Module::Build->new
    ( module_name => 'Maypole::Plugin::Authentication::UserSessionCookie',
      license     => 'perl',
      create_makefile_pl => 'passthrough',
      requires    => { 'Maypole' => 2.06 },
    )->create_build_script;
