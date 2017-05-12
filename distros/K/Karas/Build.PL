use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    dynamic_config       => 0,

    build_requires       => {
        'Test::More' => '0.98',
        'Test::Requires' => 0,
        'DBD::SQLite' => 1.37,
        'DBD::PassThrough' => 0.02,
    },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        perl => '5.010001',
        'parent'                        => '0',
        'Class::Accessor::Lite' => 0.05,
        'Module::Load' => 0,
        'String::CamelCase' => 0,
        'Scalar::Util' => 0,
        'Class::Trigger' => '0.14',
        'DBI' => '1.6.14',
        'SQL::Maker' => '1.09',
        'Data::Page::NoTotalEntries' => 0,
        'DBIx::Handler' => '0.04',
        'DBIx::Inspector' => 0,
        'DBIx::TransactionManager' => '1.11',
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => 'Karas',
    module_name => 'Karas',

    # script_files => [''],

    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,
   
    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
