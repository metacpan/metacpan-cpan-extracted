#!perl

use 5.26.0;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Food::Ratio',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Food/Ratio.pm',
    release_status     => 'stable',
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    sign               => 1,
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => { 'Test2::V0'     => '0', },
    requires           => {
        'perl'          => '5.26.0',
        'Carp'          => '0',
        'List::UtilsBy' => '0',
        'Object::Pad'   => '0.52',
        'Scalar::Util'  => '0',
    },
    add_to_cleanup => ['Food-Ratio-*'],
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
      { resources => { repository => 'https://thrig.me/src/Food-Ratio.git' } },
);

$builder->create_build_script();
