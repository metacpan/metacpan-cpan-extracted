use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Geo::Direction::Distance',
    license             => 'perl',
    dist_author         => 'OHTSUKA Ko-hei <nene@kokogiko.net>',
    dist_version_from   => 'lib/Geo/Direction/Distance.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Math::Trig' => 0,
    },
    build_requires => {
        'Test::Base' => 0,
    },
    add_to_cleanup      => [ 'Geo-Direction-Distance-*' ],
);

$builder->create_build_script();
