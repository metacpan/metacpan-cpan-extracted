#!perl
use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Logic::Expr',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Logic/Expr.pm',
    release_status     => 'stable',
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => {
        'Scalar::Util' => '0',
        'Test2::V0'    => '0.000060',
        'perl'         => '5.14.0',
    },
    requires => {
        'Exporter'     => '0',
        'Parser::MGC'  => '0.21',
        'Scalar::Util' => '0',
        'perl'         => '5.14.0',
    },
    sign           => 1,
    add_to_cleanup => ['Logic-Expr-*'],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
);

$builder->create_build_script();
