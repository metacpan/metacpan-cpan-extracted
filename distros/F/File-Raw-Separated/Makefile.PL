use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use Config;

my $pkg;
eval { $pkg = ExtUtils::Depends->new('File::Raw::Separated', 'File::Raw') };
if (!$pkg) {
    die "Cannot find File::Raw dependency (need 0.12+).\n"
      . "Install File::Raw 0.12+ or place it as a sibling directory.\n"
        unless -d '../File-Raw/include';
    $pkg = ExtUtils::Depends->new('File::Raw::Separated');
    $pkg->set_inc('-I. -I../File-Raw/include');
} else {
    my %vars = $pkg->get_makefile_vars;
    $pkg->set_inc('-I. ' . ($vars{INC} || ''));
}

my %platform_args;
if ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'openbsd'
        || $^O eq 'netbsd' || $^O eq 'dragonfly') {
    # GNU ld: allow unresolved syms, satisfied at runtime by RTLD_GLOBAL.
    $platform_args{dynamic_lib} = {
        OTHERLDFLAGS => '-Wl,--allow-shlib-undefined'
    };
}
# Windows / Cygwin / msys: nothing to do here. File::Raw 0.12+ ships a
# MinGW import library (libRaw.dll.a) and publishes its location via
# ExtUtils::Depends's set_libs(). The LIBS string flows in through
# $pkg->get_makefile_vars below, so the plugin links against Raw.dll
# automatically. This dist no longer needs to hunt for the DLL on
# disk; that workaround was the source of CPAN report 4a7ea3f4.
# macOS / other: bundle linker uses dynamic_lookup, no special handling.

my %WriteMakefileArgs = (
    NAME             => 'File::Raw::Separated',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/File/Raw/Separated.pm',
    ABSTRACT_FROM    => 'lib/File/Raw/Separated.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010000',
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'File::Raw'           => '0.13',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'File::Raw' => '0.12',
    },
    OBJECT => 'Separated$(OBJ_EXT) separated_parser$(OBJ_EXT)',
    C      => ['separated_parser.c'],
    XS     => { 'Separated.xs' => 'Separated.c' },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'File-Raw-Separated-* Separated.c Separated.o separated_parser.o' },
    %platform_args,
    # ExtUtils::Depends provides INC pointing at File::Raw's installed
    # Install/file_plugin.h. Our XS uses #include "file_plugin.h".
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
