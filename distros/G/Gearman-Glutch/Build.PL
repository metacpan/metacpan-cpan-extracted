use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    dynamic_config       => 0,

    build_requires       => {
        'Test::More' => '0.98',
        'Test::Requires' => 0,
        'Test::TCP' => 0,
        'Gearman::Client' => 0,
    },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        perl => '5.010001',
        'Gearman::Worker'                      => '0',
        'Gearman::Server'                      => '0',
        'parent'                        => '0',
        'Class::Accessor::Fast' => 0,
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => 'Gearman-Glutch',
    module_name => 'Gearman::Glutch',

    # script_files => [''],

    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,
   
    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
