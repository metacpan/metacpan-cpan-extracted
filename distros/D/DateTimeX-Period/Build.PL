use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DateTimeX::Period',
    license             => 'artistic_2',
    dist_author         => q{Vytas Dauksa <vytas.dauksa@smoothwall.net>},
    dist_version_from   => 'lib/DateTimeX/Period.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
    },
    requires => {
        'DateTime'  => 0,
        'Carp'      => 0,
        'Try::Tiny' => 0,
    },
    add_to_cleanup     => [ 'DateTimeX-Period-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
