use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Geo::GeoPo',
    license             => 'perl',
    dist_author         => 'OHTSUKA Ko-hei <nene@kokogiko.net>',
    dist_version_from   => 'lib/Geo/GeoPo.pm',
    requires => {
        'Test::Base' => 0,
        'version'    => 0,
        'Exporter'   => 0,
    },
    auto_features => {
        'Geo::Formatter::Format::GeoPo' => {
            description => "Enable to add GeoPo format to Geo::Formatter",
            requires    => {
                'Geo::Formatter' => '0.0.1',
            },
        },
    },
    add_to_cleanup      => [ 'Geo-GeoPo-*' ],
);

$builder->create_build_script();
