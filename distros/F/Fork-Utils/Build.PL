package main;

use 5.012;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name         => 'Fork::Utils',
    license             => 'apache',
    create_readme       => 1,
    configure_requires  => {
        'Module::Build' => '0.19'
    },
    build_requires       => {
        'Test::More' => 0,
    },
    requires       => {
        'perl'  => 5.012001,
        'POSIX' => 0,
    },
    needs_compiler => 0,
    meta_merge     => {
        'resources' => {
            'bugtracker' => 'https://github.com/KalessinD/perl_fork_utils/issues',
            'repository' => 'https://github.com/KalessinD/perl_fork_utils',
        },
    }
);

$build->create_build_script;

1;
__END__
