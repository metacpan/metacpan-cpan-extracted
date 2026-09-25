use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# ---- Game::Mahjong as an ABI PROVIDER ---------------------------------------
# include/mahjong_abi.h publishes the tile table: forty-two kinds, each with
# its code, suit, rank and flags. It is perl-free, so the same C compiles into
# the XS, into a plain program, or to wasm. ExtUtils::Depends installs the
# header and records the include path; Game::Mahjong::Tiles::_abi_ptr hands the
# table's address over at runtime. No set_inc, for Game::Go's reason: what is
# recorded there is handed to every consumer, and a build tree's paths mean
# nothing once installed.
my $pkg = ExtUtils::Depends->new('Game::Mahjong');
$pkg->install('include/mahjong_abi.h', 'include/mahjong_decompose.h', 'include/mahjong_shanten.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;

# EU::Depends hands back an empty LIBS and LDFROM that would clobber
# MakeMaker's own defaults, and an INC that would clobber ours below.
delete @dep{qw(LIBS LDFROM INC)};

# %dep carries its own PM key, which silently stops installing the library if
# it is left to win. Re-add every .pm by hand.
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# ---- THE PERL FLOOR, AND WHAT IS EVIDENCE FOR IT -----------------------------
#
# 5.010 is the SYNTACTIC floor: the defined-or operator appears in the modules
# and nothing later than 5.10 does. Object::Proto::Sugar, which the classes are
# written on, declares 5.008003 and does not raise this.
#
# WHAT HAS ACTUALLY BEEN RUN is recorded here, and the span between the floor
# and the oldest tested perl is INFERRED FROM THE SYNTAX AND HAS NOT BEEN
# TESTED. Saying so is the point of this comment.
#
#   tested:   5.42.0, whole suite, 23 Sep 2026 (phase 01)
#   inferred: 5.10 to 5.40, from the syntax alone
#
# ---- AND THE FLOOR NOBODY WRITES DOWN: THE COMPILER --------------------------
#
# This is an XS distribution with no pure-Perl fallback: the tile table, the
# decomposer and the shanten are C, so it needs a working compiler to do
# anything at all. There is no float in the engine, so there is no
# -ffp-contract probe (the ball engine's reason does not apply here).
#
# THE C FLOOR IS C89 for the table and the door as they stand in phase 01,
# checked with -std=c89 -pedantic -Wall -Wextra on Apple clang; the later
# phases say what they raise it to and why.
#
#   tested:   Apple clang 17, 23 Sep 2026
#   untested: gcc proper, and MSVC. /usr/bin/gcc on this machine IS clang.
#
# WITHOUT THE PROBE BELOW, a machine with no compiler gets a Makefile, a failed
# build, and a pile of linker noise. With it, it gets one sentence naming what
# is missing.

if (eval { require ExtUtils::CBuilder; 1 }) {
    my $cb = ExtUtils::CBuilder->new(quiet => 1);
    unless (eval { $cb->have_compiler }) {
        warn <<'NO_CC';

Game::Mahjong is an XS distribution: the tile table, the decomposer and the
shanten are C and there is no pure-Perl fallback, so it cannot be installed
without a working C compiler.

  Debian, Ubuntu    apt-get install build-essential
  RedHat, Fedora    dnf group install "Development Tools"
  macOS             xcode-select --install
  Windows           Strawberry Perl already has one; ActivePerl needs MSVC

Nothing else is missing. Install a compiler and run this again.

NO_CC
        exit 0;    # 0, not a die: a smoker should record NA and not FAIL
    }
}

my %WriteMakefileArgs = (
    NAME             => 'Game::Mahjong',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Game/Mahjong.pm',
    ABSTRACT_FROM    => 'lib/Game/Mahjong.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'ExtUtils::CBuilder'  => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    # EXACTLY ONE NON-CORE RUNTIME DEPENDENCY. Object::Proto::Sugar is the
    # object system of every class here; the version is WHAT HAS BEEN RUN, not
    # a known floor. Digest::SHA seeds the wall from phase 02 and is core.
    PREREQ_PM => {
        'Object::Proto::Sugar' => '0.06',
        'Digest::SHA'          => '0',
    },
    XS     => { 'Mahjong.xs' => 'Mahjong.c' },
    C      => [ 'Mahjong.c', 'mahjong_tiles.c', 'mahjong_decompose.c', 'mahjong_shanten.c' ],
    OBJECT => 'Mahjong$(OBJ_EXT) mahjong_tiles$(OBJ_EXT) mahjong_decompose$(OBJ_EXT) mahjong_shanten$(OBJ_EXT)',
    EXE_FILES => [ 'bin/mahjong' ],
    INC    => '-I. -Iinclude',
    # MakeMaker rescans no header: name it, so the objects rebuild when it
    # moves. Without this a header change produces a build that silently did
    # not happen, and the symptom is a test asserting the old ABI.
    depend => {
        'Mahjong$(OBJ_EXT)'           => 'include/mahjong_abi.h include/mahjong_decompose.h include/mahjong_shanten.h',
        'mahjong_tiles$(OBJ_EXT)'     => 'include/mahjong_abi.h',
        'mahjong_decompose$(OBJ_EXT)' => 'include/mahjong_abi.h include/mahjong_decompose.h',
        'mahjong_shanten$(OBJ_EXT)'   => 'include/mahjong_abi.h include/mahjong_shanten.h',
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Game-Mahjong-* Install' },
    %dep,
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
