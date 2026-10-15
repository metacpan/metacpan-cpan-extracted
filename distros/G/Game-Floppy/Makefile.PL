use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# ---- THE PERL FLOOR -----------------------------------------------------------
# 5.014, because Object::Proto::Sugar does not install below it (Game-Fanorona
# measured that on 5.14.4). The engine, the bot and the terminal need nothing
# newer. Raylib::FFI, which the window needs, wants 5.38; it is recommended and
# never required, and the window module compiles without it.

my %WriteMakefileArgs = (
    NAME             => 'Game::Floppy',
    AUTHOR           => q{LNATION <email@lnation.org>},
    VERSION_FROM     => 'lib/Game/Floppy.pm',
    ABSTRACT_FROM    => 'lib/Game/Floppy.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.014',
    EXE_FILES        => [ 'bin/floppy' ],
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
        'FindBin'    => '0',
        'IPC::Open3' => '0',
        'File::Temp' => '0',
        'Symbol'     => '0',
    },
    PREREQ_PM => {
        'Carp'                 => '0',
        'Digest::SHA'          => '0',
        'File::Basename'       => '0',
        'File::Spec'           => '0',
        'Getopt::Long'         => '0',
        'Object::Proto'        => '1.00',
        'Game::Terminal::Kit'  => '0.05',
        'Object::Proto::Sugar' => '1.00',
        'Time::HiRes'          => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            runtime => {
                recommends => {
                    # the terminal game reads the keys with this; without
                    # it the game can only be watched, never played by hand
                    'Term::ReadKey' => '0',
                    # the window: `floppy --raylib`; needs perl 5.38 and libraylib
                    'Raylib::FFI'   => '0.02',
                },
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/Game-Floppy.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/Game-Floppy',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Game-Floppy-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };
delete $WriteMakefileArgs{META_MERGE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 };

WriteMakefile(%WriteMakefileArgs);
