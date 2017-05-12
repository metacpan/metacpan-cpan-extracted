use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Geo::Direction::Name::Spec::Chinese',
    license             => 'perl',
    dist_author         => 'OHTSUKA Ko-hei <nene@kokogiko.net>',
    dist_version_from   => 'lib/Geo/Direction/Name/Spec/Chinese.pm',
    requires => {
        'Test::Base'           => 0,
        'version'              => 0,
        'Geo::Direction::Name' => '0.0.4',
    },
    add_to_cleanup      => [ 'Geo-Direction-Name-Spec-Chinese-*' ],
);

$builder->create_build_script();
