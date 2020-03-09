#!perl
use strict;
use warnings;
use Module::Build;
Module::Build->new(
    module_name        => 'Game::Xomb',
    dist_abstract      => 'a game featuring @ versus the Xarci Bedo',
    dist_author        => 'Jeremy Mates <jeremy.mates@gmail.com>',
    dist_version_from  => 'lib/Game/Xomb.pm',
    extra_manify_args  => { utf8 => 1 },
    include_dirs       => ['.'],
    license            => 'bsd',
    needs_compiler     => 1,
    release_status     => 'stable',                                    # LOL
    sign               => 1,
    configure_requires => {
        'CPAN::Meta'    => '2.142060',
        'Module::Build' => '0.4004',     # test_requires
    },
    requires => {
        'perl'          => '5.24.0',
        'strict'        => 0,
        'List::Util'    => 0,
        'List::UtilsBy' => 0,
        'POSIX'         => 0,
        'Scalar::Util'  => 0,
        'Term::ReadKey' => 0,
        'Time::HiRes'   => 0,
        'XSLoader'      => 0,
    },
    test_requires => {
        'strict'            => 0,
        'Scalar::Util'      => 0,
        'Test::More'        => '0.88',    # done_testing
        'Test::Most'        => 0,
        'Test::UnixCmdWrap' => 0,
    },
    add_to_cleanup => ['Game-Xomb-*'],
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
        resources => { repository => 'https://github.com/thrig/Game-Xomb' }
    },
)->create_build_script();
