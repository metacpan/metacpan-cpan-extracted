#!perl
use 5.26.0;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Game::Deckar',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jmates@thrig.me>},
    dist_version_from  => 'lib/Game/Deckar.pm',
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    release_status     => 'stable',
    sign               => 1,
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => {
        'Scalar::Util' => '0',
        'Test2::V0'    => '0.000060',
        'perl'         => '5.26.0',
    },
    requires => {
        'Object::Pad' => '0.66',
        'perl'        => '5.26.0',
    },
    add_to_cleanup => ['Game-Deckar-*'],
    meta_merge     => {
        resources => { repository => 'https://thrig.me/src/Game-Deckar.git' }
    },
);

$builder->create_build_script();
