#!perl
use 5.8.0;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'File::Cmp',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jmates@cpan.org>},
    dist_version_from  => 'lib/File/Cmp.pm',
    release_status     => 'stable',
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => { 'Test2::V0'     => '0.000060', },
    requires           => {
        perl           => '5.8.0',
        Carp           => 0,
        Exporter       => 0,
        'Scalar::Util' => 0,
    },
    sign           => 1,
    add_to_cleanup => ['File-Cmp-*'],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge =>
      { resources => { repository => 'https://thrig.me/src/File-Cmp.git' } },
);

$builder->create_build_script();
