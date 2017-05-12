use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'File::CleanupTask',
    license             => 'perl',
    dist_author         => q{Savio Dimatteo <savio@lokku.com>},
    dist_version_from   => 'lib/File/CleanupTask.pm',
    configure_requires => { 
        'Module::Build' => 0.38 
    },
    build_requires => {
        'Test::More'          => 0,
        'Test::File'          => 1.33,
        'File::Temp'          => 0,
        'File::Touch'         => 0,
        'File::Find::Rule'    => 0,
        'File::Basename'      => 0,
        'File::Path'          => 0,
        'File::Spec'          => 0,
        'Config::Simple'      => 0,
        'Cwd'                 => 0,
        'Test::CheckManifest' => 0,
        'Test::Pod::Coverage' => 0,
        'Test::Pod'           => 0,
    },
    requires => {
        'perl'           => 5.006,
        'File::Path'     => 0,
        'File::Basename' => 0,
        'File::Spec'     => 0,
        'File::Find'     => 0,
        'File::Copy'     => 0,
        'IPC::Run3'      => 0,
        'Sort::Key'      => 0,
        'File::Which'    => 0,
        'Config::Simple' => 0,
        'Getopt::Long'   => 0,


    },
    add_to_cleanup      => [ 'File-CleanupTask-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
