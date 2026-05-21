use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use Config;

my $pkg;
eval {
    $pkg = ExtUtils::Depends->new('File::Raw::JSON',
                                   'File::Raw',
                                   'Tie::OrderedHash');
};
if (!$pkg) {
    die "Cannot find File::Raw and/or Tie::OrderedHash dependencies.\n"
      . "Install File::Raw 0.12+ and Tie::OrderedHash 0.01+, or place\n"
      . "them as sibling directories.\n"
        unless -d '../File-Raw/include' && -d '../Tie-OrderedHash/include';
    $pkg = ExtUtils::Depends->new('File::Raw::JSON');
    $pkg->set_inc('-I. -Iinclude -I../File-Raw/include -I../Tie-OrderedHash/include');
} else {
    my %vars = $pkg->get_makefile_vars;
    $pkg->set_inc('-I. -Iinclude ' . ($vars{INC} || ''));
}


my %platform_args;
if ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'openbsd'
        || $^O eq 'netbsd' || $^O eq 'dragonfly') {
    $platform_args{dynamic_lib} = {
        OTHERLDFLAGS => '-Wl,--allow-shlib-undefined'
    };
}

my %WriteMakefileArgs = (
    NAME             => 'File::Raw::JSON',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/File/Raw/JSON.pm',
    ABSTRACT_FROM    => 'lib/File/Raw/JSON.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010000',
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'File::Raw'           => '0.12',
        'Tie::OrderedHash'    => '0.02',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'File::Raw'        => '0.12',
        'Tie::OrderedHash' => '0.02',
    },
    OBJECT => 'JSON$(OBJ_EXT) file_raw_json$(OBJ_EXT) yyjson$(OBJ_EXT)',
    C      => ['file_raw_json.c', 'yyjson.c'],
    XS     => { 'JSON.xs' => 'JSON.c' },
    # Force yyjson to pull <stdint.h> / <stdbool.h> unconditionally.
    # Without these, yyjson's "is C99 / is MSVC / has __has_include?"
    # auto-detect falls into a typedef-fallback path on older toolchains
    # (eg gcc 4.2 on FreeBSD 9.2) and re-typedefs int64_t / uint64_t,
    # colliding with the system header already in scope via perl.h:
    #   include/yyjson.h:435: error: conflicting types for 'int64_t'
    # Every Unix in our support window has both headers, so forcing is
    # safe.
    DEFINE => '-DYYJSON_HAS_STDINT_H=1 -DYYJSON_HAS_STDBOOL_H=1',
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean  => {
        FILES => 'File-Raw-JSON-* JSON.c JSON.o file_raw_json.o yyjson.o'
    },
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
