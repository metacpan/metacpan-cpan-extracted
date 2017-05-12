use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Hash::DeepAccess',
    license             => 'artistic_2',
    dist_author         => q{Jonas Kramer <jkramer@mark17.net>},
    dist_version_from   => 'lib/Hash/DeepAccess.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
		Want => 0.22,
    },
    add_to_cleanup     => [ 'Hash-DeepAccess-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
