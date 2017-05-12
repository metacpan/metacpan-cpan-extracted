use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Geo::Google::MyMap::KMLURL',
    license             => 'perl',
    dist_author         => 'OHTSUKA Ko-hei <nene@kokogiko.net>',
    dist_version_from   => 'lib/Geo/Google/MyMap/KMLURL.pm',
    requires => {
        'Test::Base' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Geo-Google-MyMap-KMLURL-*' ],
);

$builder->create_build_script();
