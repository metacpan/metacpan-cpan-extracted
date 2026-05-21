use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use Config;

# Pick up File::Raw's published file_plugin.h via ExtUtils::Depends.
# Falls back to a sibling working copy when developing in tree.
my $pkg;
eval { $pkg = ExtUtils::Depends->new('File::Raw::Hash', 'File::Raw') };
if (!$pkg) {
    die "Cannot find File::Raw dependency (need 0.13+).\n"
      . "Install File::Raw 0.13+ or place it as a sibling directory.\n"
        unless -d '../File-Raw/include';
    $pkg = ExtUtils::Depends->new('File::Raw::Hash');
    $pkg->set_inc('-Iinclude -I../File-Raw/include');
} else {
    my %vars = $pkg->get_makefile_vars;
    $pkg->set_inc('-Iinclude ' . ($vars{INC} || ''));
}

my %platform_args;
if ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'openbsd'
        || $^O eq 'netbsd' || $^O eq 'dragonfly') {
    # GNU ld: allow unresolved syms, satisfied at runtime by RTLD_GLOBAL.
    $platform_args{dynamic_lib} = {
        OTHERLDFLAGS => '-Wl,--allow-shlib-undefined'
    };
}
# Windows / Cygwin / msys: nothing to do here. File::Raw 0.13+ ships a
# MinGW import library (libRaw.dll.a) and publishes its location via
# ExtUtils::Depends's set_libs(). The LIBS string flows in through
# $pkg->get_makefile_vars below, so the plugin links against Raw.dll
# automatically. This dist no longer needs to hunt for the DLL on
# disk.

my %WriteMakefileArgs = (
    NAME             => 'File::Raw::Hash',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/File/Raw/Hash.pm',
    ABSTRACT_FROM    => 'lib/File/Raw/Hash.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'File::Raw'           => '0.13',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'File::Raw' => '0.13',
    },
    OBJECT => 'Hash$(OBJ_EXT) hashx$(OBJ_EXT) sha2$(OBJ_EXT) '
            . 'sha1$(OBJ_EXT) md5$(OBJ_EXT) crc32$(OBJ_EXT) '
            . 'xxh64$(OBJ_EXT) blake3$(OBJ_EXT)',
    C      => ['hashx.c', 'sha2.c', 'sha1.c', 'md5.c', 'crc32.c',
               'xxh64.c', 'blake3.c'],
    XS     => { 'Hash.xs' => 'Hash.c' },
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean  => { FILES => 'File-Raw-Hash-* Hash.c Hash.o '
                       . 'hashx.o sha2.o sha1.o md5.o crc32.o '
                       . 'xxh64.o blake3.o' },
    %platform_args,
    $pkg->get_makefile_vars,
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

WriteMakefile(%WriteMakefileArgs);
