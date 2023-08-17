#!perl
use 5.10.0;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');
my $builder = Module::Build->new(
    module_name        => 'MIDI::Segment',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jmates@thrig.me>},
    dist_version_from  => 'lib/MIDI/Segment.pm',
    release_status     => 'stable',
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => { 'MIDI' => '0', 'Test2::V0' => '0.000060', },
    requires           => { 'MIDI' => '0', 'perl'      => '5.10.0', },
    sign               => 1,
    add_to_cleanup     => ['MIDI-Segment-*'],
    auto_features      => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge => {
        resources => { repository => 'https://thrig.me/src/MIDI-Segment.git' }
    },
);
$builder->create_build_script();
