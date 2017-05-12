use 5.006;
use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new(
    license              => 'perl',
    module_name          => 'Getopt::CallingName',
    requires             => {
        'Test::More' => 0,
    },
    create_readme        => 1,
    add_to_cleanup       => [ '*.tar.gz', 'Build', '_build' ],
)->create_build_script;
