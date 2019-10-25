#!perl
use 5.14.0;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Lingua::Awkwords',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Lingua/Awkwords.pm',
    release_status     => 'stable',
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => {
        'perl'       => '5.14.0',
        'strict'     => 0,
        'Test::Most' => 0,
    },
    requires => {
        'perl'                   => '5.14.0',
        'Carp'                   => 0,
        'Math::Random::Discrete' => 0,
        'Moo'                    => 0,
        'namespace::clean'       => 0,
        'Parser::MGC'            => 0,
        'strict'                 => 0,
    },
    sign           => 1,
    add_to_cleanup => [ 'Lingua-Awkwords-*', 't/*.out' ],
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
      { resources => { repository => 'https://github.com/thrig/Lingua-Awkwords' } },
);

$builder->create_build_script();
