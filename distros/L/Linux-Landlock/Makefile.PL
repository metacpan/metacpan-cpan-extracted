use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT           => 'An interface to the Landlock sandboxing facility of Linux',
    AUTHOR             => 'Marc Ballarin <ballarin.marc@gmx.de>',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0
    },
    DISTNAME  => 'Linux-Landlock',
    LICENSE   => 'perl',
    NAME      => 'Linux::Landlock',
    PREREQ_PM => {
        'POSIX'      => 0,
        'List::Util' => 0,
        'Exporter'   => 0,
        'Config'     => 0,
    },
    VERSION       => '0.5',
    TEST_REQUIRES => {
        'Test::Exception'  => 0,
        'Test::More'       => 0,
        'File::Basename'   => 0,
        'IO::Dir'          => 0,
        'IO::File'         => 0,
        'IO::Socket::INET' => 0,
    },
    test => {
        TESTS => 't/*.t'
    },
    META_MERGE => {
        osname      => 'linux',
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/mballarin/perl-linux-landlock.git',
                web  => 'https://github.com/mballarin/perl-linux-landlock',
            },
            bugtracker => {
                web => 'https://github.com/mballarin/perl-linux-landlock/issues'
            },
        },
    },
);
