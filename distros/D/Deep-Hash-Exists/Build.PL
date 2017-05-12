use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Deep::Hash::Exists',
    license             => 'perl_5',
    dist_author         => q{Vitaly Simul <vitalysimul@gmail.com>},
    dist_version_from   => 'lib/Deep/Hash/Exists.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Scalar::Util' => 1.02,
    },
    add_to_cleanup     => [ 'Deep-Hash-Exists-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
