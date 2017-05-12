use strict;
use Module::Build;
Module::Build->new(
    module_name => 'Hook::Queue',
    license     => 'perl',
    requires    => {
        'perl' => 5.006, # has a suitable version of Devel::Peek (CvGV)
    },
    build_requires => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'traditional',
   )->create_build_script;
