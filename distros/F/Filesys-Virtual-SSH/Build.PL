use strict;
use Module::Build;
Module::Build->new(
    module_name => 'Filesys::Virtual::SSH',
    license     => 'perl',
    requires    => {
        'perl' => 5.006,
        'Filesys::Virtual'        => 0,
        'Filesys::Virtual::Plain' => 0,
        'String::ShellQuote'      => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'File::Slurp::Tree' => 0,
    },
    create_makefile_pl => 'traditional',
   )->create_build_script;
