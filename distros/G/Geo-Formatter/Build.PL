use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Geo::Formatter',
    license             => 'perl',
    dist_author         => 'OHTSUKA Ko-hei <nene@kokogiko.net>',
    dist_version_from   => 'lib/Geo/Formatter.pm',
    requires => {
        'Test::Base'         => 0,
        'version'            => 0,
        'Exporter'           => 0,
        'Class::Inspector'   => 0,
        'UNIVERSAL::require' => 0,
    },
    add_to_cleanup      => [ 'Geo-Formatter-*' ],
);

$builder->create_build_script();
