use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Geo::Coder::GoogleMaps',
    license             => 'perl',
    dist_author         => 'Arnaud DUPUIS <a.dupuis@nabladev.com>',
    dist_version_from   => 'lib/Geo/Coder/GoogleMaps.pm',
    build_requires => {
        'Test::More' => 0,
        'XML::LibXML' => 1.60,
        'JSON::Syck' => 0.07,
        'HTTP::Request' => 0,
        'LWP::UserAgent' => 0,
        'URI' => 0
    },
    add_to_cleanup      => [ 'Geo-Coder-GoogleMaps-*' ],
);

$builder->create_build_script();
