use strict;
use warnings;
use version 0.77;
use ExtUtils::MakeMaker 6.64;
use English qw(-no_match_vars);

die "This module can only be built on macOS (darwin)\n"
    if $OSNAME ne 'darwin';

my $macos = `sw_vers -productVersion`;    ## no critic (InputOutput::ProhibitBacktickOperators)
chomp $macos;
die "This module requires macOS 10.12 Sierra or newer\n"
    if version->parse($macos) < version->parse('10.12');

WriteMakefile(
    NAME          => 'Log::Any::Adapter::MacOS::OSLog',
    AUTHOR        => ['Mark Gardner <mjgardner@cpan.org>'],
    VERSION_FROM  => 'lib/Log/Any/Adapter/MacOS/OSLog.pm',
    ABSTRACT_FROM => 'lib/Log/Any/Adapter/MacOS/OSLog.pm',
    LICENSE       => 'perl_5',
    META_MERGE    => {
        'meta-spec'    => { version => 2 },
        release_status => 'stable',
        provides       => {
            'Log::Any::Adapter::MacOS::OSLog' => {
                file    => 'lib/Log/Any/Adapter/MacOS/OSLog.pm',
                version => 'v0.0.4',
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  =>
                    'https://codeberg.org/mjgardner/perl-Log-Any-Adapter-MacOS-OSLog.git',
                web =>
                    'https://codeberg.org/mjgardner/perl-Log-Any-Adapter-MacOS-OSLog',
            },
            license =>
                'https://codeberg.org/mjgardner/perl-Log-Any-Adapter-MacOS-OSLog/raw/branch/main/LICENSE',
            bugtracker => {
                web =>
                    'https://codeberg.org/mjgardner/perl-Log-Any-Adapter-MacOS-OSLog/issues',
            },
        },
    },

    MIN_PERL_VERSION => '5.018',
    BUILD_REQUIRES   => {
        'ExtUtils::MakeMaker' => '6.64',
        'version'             => '0.77',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
        'version'             => '0.77',
    },
    TEST_REQUIRES => {
        'Test2::V0'    => 0,
        'Test::Script' => '1.05',
    },
    PREREQ_PM => {
        'Log::Any::Adapter::Base' => 0,
        'Log::Any::Adapter::Util' => 0,
        'FFI::Platypus'           => '2.00',
        'namespace::autoclean'    => 0,
    },
    TEST_REQUIRES => {
        'Test2::V0'    => 0,
        'Test::Script' => '1.05',
    },

    C           => ['oslog_wrapper.c'],
    OBJECT      => 'oslog_wrapper.o',
    CCFLAGS     => '-mmacosx-version-min=10.12',
    dynamic_lib => { OTHERLDFLAGS => '-framework OSLog' },
    EXE_FILES   => ['script/maclog'],

    dist => { TAR => 'gtar', },
);
