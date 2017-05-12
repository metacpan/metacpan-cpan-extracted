use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Maple',
    license             => 'perl',
    dist_author         => q{Eugene Au <eugene.au@live.ca>},
    dist_version_from   => 'lib/Maple.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Maple-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
