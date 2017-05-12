use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Geo::StreetAddress::FR',
    dist_abstract       => 'Geo::StreetAddress::FR is a street address parser for France.',
    license             => 'perl',
    dist_author         => 'franck cuny <franck.cuny@gmail.com>',
    dist_version_from   => 'lib/Geo/StreetAddress/FR.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Test::Perl::Critic' => 0,
        'Class::Accessor::Fast' => 0,
    },
    add_to_cleanup      => [ 'Geo-StreetAddress-FR-*' ],
);

$builder->create_build_script();
