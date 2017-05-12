use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Geo::Hex',
    license             => 'perl',
    dist_author         => 'OHTSUKA Ko-hei <nene@kokogiko.net>',
    dist_version_from   => 'lib/Geo/Hex.pm',
    requires => {
        'Test::Base'     => 0,
        'version'        => 0,
        'Exporter'       => 0,
        'POSIX'          => 0,
        'Math::Round'    => 0,
        'Math::Trig'     => 0,
        'Geo::Proj4'     => 0,
    },
    add_to_cleanup      => [ 'Geo-Hex-*' ],
);

$builder->create_build_script();
