#!perl
use strict;
use warnings;
use Module::Build;
Module::Build->new(
    module_name        => 'Math::SlideRule',
    dist_abstract      => 'slide rule support for Perl',
    dist_author        => 'Jeremy Mates <jeremy.mates@gmail.com>',
    dist_version_from  => 'lib/Math/SlideRule.pm',
    license            => 'bsd',
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    release_status     => 'stable',
    sign               => 1,
    configure_requires => {
        'CPAN::Meta'    => '2.142060',
        'Module::Build' => '0.4004',     # test_requires
    },
    requires => {
        'perl'             => '5.10.0',
        'strict'           => 0,
        'Moo'              => 0,
        'namespace::clean' => 0,
        'Scalar::Util'     => 0,
    },
    test_requires => {
        'strict'     => 0,
        'Test::More' => '0.88',          # done_testing
        'Test::Most' => 0,
    },
    add_to_cleanup => ['Math-SlideRule-*'],
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
      { resources => { repository => 'https://github.com/thrig/Math-SlideRule' } },
)->create_build_script();
