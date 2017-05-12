use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Dir::Which',
    license             => 'perl',
    dist_author         => 'Jacquelin <jacquelin.charbonnel>',
    dist_version_from   => 'lib/Dir/Which.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Dir-Which-*' ],
);

$builder->create_build_script();
