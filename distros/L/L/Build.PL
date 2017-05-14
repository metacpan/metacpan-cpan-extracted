use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    license        => 'perl',
    dynamic_config => 0,
    dist_abstract  => 'Module loader for one liner.',

    build_requires     => {
        'Test::More'     => '0.98',
        'Test::Requires' => '0.06',
    },
    configure_requires => { 'Module::Build' => '0.38' },
    requires           => {
        perl           => '5.008001',
        'Module::Load' => 0,
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => 'L',
    module_name => 'L',

    test_files           => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,

    create_makefile_pl => 'traditional',
    create_readme      => 1,
    create_license     => 1,
);
$build->create_build_script;
