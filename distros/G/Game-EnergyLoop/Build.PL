#!perl
use strict;
use warnings;
use Module::Build;
Module::Build->new(
    module_name        => 'Game::EnergyLoop',
    license            => 'bsd',
    dist_author        => 'Jeremy Mates <jmates@thrig.me>',
    dist_version_from  => 'lib/Game/EnergyLoop.pm',
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    release_status     => 'stable',
    sign               => 1,
    configure_requires => {
        'CPAN::Meta'    => '2.142060',
        'Module::Build' => '0.4004',     # test_requires
    },
    test_requires  => { 'Test2::V0' => '0', },
    add_to_cleanup => ['Game-EnergyLoop-*'],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge => {
        resources =>
          { repository => 'https://thrig.me/src/Game-EnergyLoop.git' }
    },
)->create_build_script();
