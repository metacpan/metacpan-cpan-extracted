#!perl
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Game::RaycastFOV',
    license            => 'bsd',
    dist_author        => 'Jeremy Mates <jeremy.mates@gmail.com>',
    dist_version_from  => 'lib/Game/RaycastFOV.pm',
    dist_abstract      => 'raycast field-of-view and related routines',
    include_dirs       => [qw(.)],
    release_status     => 'stable',
    configure_requires => {
        'CPAN::Meta'    => '2.142060',
        'Module::Build' => '0.4004',     # test_requires
    },
    requires => {
        'perl'       => '5.10.0',
        'strict'     => 0,
        'Math::Trig' => 0,
    },
    test_requires => {
        'strict'     => 0,
        'Math::Trig' => 0,
        'Test::More' => '0.88',          # done_testing
        'Test::Most' => 0,
    },
    sign           => 1,
    add_to_cleanup => ['Game-RaycastFOV-*'],
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
          { repository => 'https://github.com/thrig/Game-RaycastFOV' }
    },
);

$builder->create_build_script();
