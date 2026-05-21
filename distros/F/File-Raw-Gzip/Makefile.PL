use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use Devel::CheckLib;
use Config;

# Probe zlib at configure time. If it isn't there, exit 0
unless (check_lib(lib => 'z', header => 'zlib.h')) {
    print STDERR <<'EOM';
zlib (header and library) not found.
OS unsupported: install your platform's zlib development package and
re-run Makefile.PL:

  Debian/Ubuntu : apt-get install zlib1g-dev
  RHEL/Fedora   : dnf install zlib-devel
  Homebrew      : brew install zlib
  FreeBSD       : pkg install zlib-ng-compat
  Strawberry    : already bundled, no install needed
EOM
    exit 0;
}

# Pick up File::Raw's published file_plugin.h via ExtUtils::Depends.
# Falls back to a sibling working copy when developing in tree.
my $pkg;
eval { $pkg = ExtUtils::Depends->new('File::Raw::Gzip', 'File::Raw') };
if (!$pkg) {
    die "Cannot find File::Raw dependency (need 0.13+).\n"
      . "Install File::Raw 0.13+ or place it as a sibling directory.\n"
        unless -d '../File-Raw/include';
    $pkg = ExtUtils::Depends->new('File::Raw::Gzip');
    $pkg->set_inc('-I. -I../File-Raw/include');
} else {
    my %vars = $pkg->get_makefile_vars;
    $pkg->set_inc('-I. ' . ($vars{INC} || ''));
}
$pkg->set_libs('-lz');

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
# ExtUtils::Depends's set_libs, which we pulled in above through
# `ExtUtils::Depends->new('File::Raw::Gzip', 'File::Raw')`. The
# resulting LIBS line includes -L"$arch/auto/File/Raw" -lRaw, so the
# linker resolves File::Raw's symbols cleanly without us hunting for
# Raw.dll on disk.

my %WriteMakefileArgs = (
    NAME             => 'File::Raw::Gzip',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/File/Raw/Gzip.pm',
    ABSTRACT_FROM    => 'lib/File/Raw/Gzip.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'Devel::CheckLib'     => '1.03',
        'File::Raw'           => '0.13',
    },
    TEST_REQUIRES => {
        'Test::More'             => '0',
        'IO::Compress::Gzip'     => '0',
        'IO::Compress::Deflate'  => '0',
        'IO::Uncompress::Gunzip' => '0',
    },
    PREREQ_PM => {
        'File::Raw' => '0.13',
    },
    OBJECT => 'Gzip$(OBJ_EXT) gz$(OBJ_EXT)',
    C      => ['gz.c'],
    XS     => { 'Gzip.xs' => 'Gzip.c' },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'File-Raw-Gzip-* Gzip.c Gzip.o gz.o' },
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
