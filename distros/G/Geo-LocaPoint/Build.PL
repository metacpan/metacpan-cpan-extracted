use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Geo::LocaPoint',
    license             => 'perl',
    dist_author         => 'OHTSUKA Ko-hei <nene@kokogiko.net>',
    dist_version_from   => 'lib/Geo/LocaPoint.pm',
    requires => {
        'Test::Base'  => 0,
        'version'     => 0,
        'Math::Round' => 0,
    },
    auto_features => {
        'Geo::Formatter::Format::LocaPoint' => {
            description => "Enable to use LocaPoint format with Geo::Formatter",
            requires    => {
                'Geo::Formatter'             => '0.0.1',
            },
        },
    },
    add_to_cleanup      => [ 'Geo-LocaPoint-*' ],
);

$builder->create_build_script();
