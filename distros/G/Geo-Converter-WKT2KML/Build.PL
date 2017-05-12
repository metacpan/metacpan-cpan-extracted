use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Geo::Converter::WKT2KML',
    license             => 'perl',
    dist_author         => 'OHTSUKA Ko-hei <nene@kokogiko.net>',
    dist_version_from   => 'lib/Geo/Converter/WKT2KML.pm',
    requires => {
        'Test::Base'  => 0,
        'version'     => 0,
        'Exporter'    => 0,
        'XML::Simple' => 0,
        'XML::Parser' => 0,
    },
    add_to_cleanup      => [ 'Geo-Converter-WKT2KML-*' ],
);

$builder->create_build_script();
