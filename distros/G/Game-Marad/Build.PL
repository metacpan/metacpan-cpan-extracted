#!perl
#
#   perl Build.PL && ./Build test && ./Build install
#
# see the README file for details

use 5.26.0;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name       => 'Game::Marad',
    license           => 'bsd',
    dist_author       => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from => 'lib/Game/Marad.pm',
    release_status    => 'stable',
    # NOTE bin/pmarad wants Curses but that's not required here
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => { 'Test2::V0'     => '0.000060', },
    requires           => { 'perl'          => '5.26.0', 'Object::Pad' => '0.52' },
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    sign               => 1,
    add_to_cleanup     => ['Game-Marad-*'],
    auto_features      => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge =>
      { resources => { repository => 'https://thrig.me/src/Game-Marad.git' } },
);

$builder->create_build_script();
