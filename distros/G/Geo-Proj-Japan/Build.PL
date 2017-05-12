use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Geo::Proj::Japan',
    license             => 'perl',
    dist_author         => 'OHTSUKA Ko-hei <nene@kokogiko.net>',
    dist_version_from   => 'lib/Geo/Proj/Japan.pm',
    requires => {
        'version'    => 0,
        'Geo::Proj'  => '0.06',
    },
    build_requires => {
        'Test::Base' => 0,
    },
    add_to_cleanup      => [ 'Geo-Proj-Japan-*' ],
);

$builder->create_build_script();
