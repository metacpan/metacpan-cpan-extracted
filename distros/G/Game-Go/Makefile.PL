use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# ---- Game::Go as an ABI PROVIDER ---------------------------------------------
# go_abi.h publishes the board: points, colours, chains, exact liberties, a
# zobrist hash and a packed position. It is perl-free, so the same C compiles
# into the XS, into a plain program, or to wasm. ExtUtils::Depends installs the
# header and records the include path; Game::Go::Engine::_abi_ptr hands the
# table's address over at runtime. No set_inc, for the sibling's reason: what is
# recorded there is handed to every consumer, and a build tree's paths mean
# nothing once installed.
my $pkg = ExtUtils::Depends->new('Game::Go');
$pkg->install('include/go_abi.h');
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
# and nothing later than 5.10 does. Object::Proto::Sugar, which the rules layer
# will depend on from phase 03, declares 5.008003 and does not raise this.
#
# WHAT HAS ACTUALLY BEEN RUN is recorded here, and the span between the floor
# and the oldest tested perl is INFERRED FROM THE SYNTAX AND HAS NOT BEEN
# TESTED. Saying so is the point of this comment: the scaffolding this file
# replaced claimed 5.008003 on no evidence at all.
#
#   tested:   5.34.1 and 5.42.0, whole suite, 18 Sep 2026
#   inferred: 5.10 to 5.34, from the syntax alone
#
# The 5.34 run found two shadowed `my` declarations that 5.42 does not warn
# about, which is the whole argument for running the old one: a module that
# warns on load fails an installer's smoke test, and the newest perl is the one
# least likely to tell you.
#
# ---- AND THE FLOOR NOBODY WRITES DOWN: THE COMPILER --------------------------
#
# This is an XS distribution with no pure-Perl fallback, so it needs a working
# compiler to do anything at all. There is deliberately no -ffp-contract=off
# probe here: the sibling ball engine needs one because its doubles must round
# identically on every platform, and this engine HAS NO FLOATS. Copying the
# probe over would be cargo.
#
# THE C FLOOR IS C99, AND THAT WAS MEASURED RATHER THAN ASSUMED. Both C files
# compile with no output at all under -std=c99, c11 and c17, each with
# -pedantic -Wall -Wextra, on Apple clang 17 and on Homebrew clang 22.
#
# C89 IS THE ONE THAT IS NOT CLEAN, and it is worth naming what makes it so:
# `unsigned long long hash` in include/go_abi.h, the zobrist key. That is the
# whole of it. A C89 compiler is the one toolchain this header cannot be
# consumed from, and lowering the floor would mean carrying the key as two
# 32-bit halves through the ABI, which is a change to the published interface
# and not a build-system decision.
#
#   tested:   Apple clang 17.0.0, Homebrew clang 22.1.8, 18 Sep 2026
#   untested: gcc proper, and MSVC. /usr/bin/gcc on this machine IS clang,
#             which is not a second compiler however it is spelled.
#
# WITHOUT THE PROBE BELOW, a machine with no compiler gets a Makefile, a failed
# build, and a pile of linker noise. With it, it gets one sentence naming what
# is missing. That is decision four's cost and this is the cheapest place to pay
# it: an engine that is entirely C cannot degrade into a slower pure-Perl one,
# so "no compiler" means "no distribution" and it should say so in words.

if (eval { require ExtUtils::CBuilder; 1 }) {
    my $cb = ExtUtils::CBuilder->new(quiet => 1);
    unless (eval { $cb->have_compiler }) {
        warn <<'NO_CC';

Game::Go is an XS distribution: the whole engine is C and there is no pure-Perl
fallback, so it cannot be installed without a working C compiler.

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
    NAME             => 'Game::Go',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Game/Go.pm',
    ABSTRACT_FROM    => 'lib/Game/Go.pm',
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
    # THE RUNTIME DEPENDENCIES, and there are two rather than the one the plan
    # expected. Object::Proto::Sugar is the facade layer in eight modules;
    # Digest::SHA seeds the bot. Both were used and neither was declared, which
    # is a clean install that boot-fails on a machine that happens not to have
    # them. Digest::SHA is core, so it would have been there, and that is
    # exactly why nothing noticed.
    #
    # The Object::Proto::Sugar version is WHAT HAS BEEN RUN, not a known floor.
    # Nothing here has been tested against an older one.
    PREREQ_PM => {
        'Object::Proto::Sugar' => '0.06',
        'Digest::SHA'          => '0',
    },
    # The two programs. Both are Getopt::Long and two filehandles, and neither
    # is needed by anything in lib/, so an installer who wants only the engine
    # loses nothing by them.
    EXE_FILES => [ 'bin/go', 'bin/go-gtp' ],
    XS     => { 'Go.xs' => 'Go.c' },
    C      => [ 'Go.c', 'go_engine.c', 'go_search.c' ],
    OBJECT => 'Go$(OBJ_EXT) go_engine$(OBJ_EXT) go_search$(OBJ_EXT)',
    INC    => '-I. -Iinclude',
    # MakeMaker rescans no header: name it, so the objects rebuild when it
    # moves. Without this a header change produces a build that silently did
    # not happen, and the symptom is a test asserting the old ABI.
    depend => {
        'Go$(OBJ_EXT)'        => 'include/go_abi.h',
        'go_engine$(OBJ_EXT)' => 'include/go_abi.h',
        'go_search$(OBJ_EXT)' => 'include/go_abi.h',
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Game-Go-* Install' },
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
