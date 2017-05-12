use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Geo::IATA',
    license             => 'perl',
    dist_author         => 'Joerg Meltzer <joerg <at> joergmeltzer.de>',
    dist_version_from   => 'lib/Geo/IATA.pm',
    requires => {
        'Test::More'     => 0,
        'version'        => 0,
        'DBI'            => 0,
        'DBD::SQLite'    => 0,
        'Sub::Install'    => 0,
    },
    add_to_cleanup      => [ 'Geo-IATA-*' ],
);
$builder->add_build_element('db');
$builder->create_build_script();
