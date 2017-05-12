use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Iphone::SMS',
    license             => 'Artistic_2_0',
    dist_author         => q{Nianhua Wei <willian.wnh@gmail.com>},
    dist_version_from   => 'lib/Iphone/SMS.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        DBI                 => 1.611,
    },
    add_to_cleanup     => [ 'Iphone-SMS-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
