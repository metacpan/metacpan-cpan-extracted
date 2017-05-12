use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MARC::File::MiJ',
    license             => 'perl',
    dist_author         => q{Bill Dueber <dueberb@umich.edu>},
    dist_version_from   => 'lib/MARC/File/MiJ.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'ex::monkeypatched' => 0,
        'JSON'              => 0,
        'MARC::File'        => 0,
        'MARC::Record'      => 0,
    },
    add_to_cleanup     => [ 'MARC-MiJ-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
