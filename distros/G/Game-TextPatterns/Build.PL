#!perl
use 5.24.0;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Game::TextPatterns',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Game/TextPatterns.pm',
    release_status     => 'stable',
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => {
        'Algorithm::Diff' => 0,
        'File::Spec'      => 0,
        'Test::More'      => '0.88',    # done_testing
        'Test::Most'      => '0',
        # TODO same story as 'strict' below
        'constant' => '0',
    },
    requires => {
        'perl'             => '5.24.0',
        'Carp'             => '0',
        'List::Util'       => '0',
        'Moo'              => '0',
        'MooX::Rebuild'    => '0',
        'Scalar::Util'     => '0',
        'namespace::clean' => '0',
        # TODO Centos8 still has the "perl-core" chop-shop thing, maybe
        # in Centos9 this will (finally) be fixed? until then, pull in
        # what RedHat has broken out so RPM deps don't derp
        'strict' => '0',
    },
    sign           => 1,
    add_to_cleanup => ['Game-TextPatterns-*'],
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
        resources => { repository => 'https://github.com/thrig/Game-TextPatterns' }
    },
);

$builder->create_build_script();
