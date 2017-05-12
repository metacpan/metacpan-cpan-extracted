use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    dynamic_config       => 0,

    build_requires       => {
        'Test::More' => '0.98',
        'Test::Requires' => 0,
    },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        perl                    => '5.008005',
        'Data::Dumper'          => '0',
        'Scalar::Util'          => '0',
        'parent'                => '0',
        'Class::Accessor::Lite' => '0.05',
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => 'Exception-Tiny',
    module_name => 'Exception::Tiny',

    # script_files => [''],

    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,

    create_readme  => 1,
    create_license => 1,

    meta_merge => {
        resources => {
            repository => 'git://github.com/yappo/p5-Exception-Tiny.git',
            homepage   => 'https://github.com/yappo/p5-Exception-Tiny',
        },
    },
);
$build->create_build_script();
