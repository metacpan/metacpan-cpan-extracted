use strict;
use Module::Build;
Module::Build->new(
    module_name => 'File::Find::Rule::Filesys::Virtual',
    license     => 'perl',
    requires    => {
        'perl' => 5.006,
        'Filesys::Virtual' => 0, # only really needed for the tests,
                                 # but if you're not going to install
                                 # it what the heck do you want with
                                 # this module?
        'File::Find::Rule' => 0.28,
    },
    build_requires => {
        'Filesys::Virtual::Plain' => 0,
        'Test::More' => 0,
    },
    create_makefile_pl => 'traditional',
   )->create_build_script;
