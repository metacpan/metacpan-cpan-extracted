use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# ---- Game::Fanorona as an ABI PROVIDER ----------------------------------------
# fn_abi.h publishes the board: the points, which are strong, which are joined,
# the stones, a key and the position string; and a step, what it takes, do and
# undo. It is perl-free, so the same C
# compiles into the XS, into a plain program, or to wasm. ExtUtils::Depends
# installs the header and records the include path;
# Game::Fanorona::Engine::_abi_ptr hands the table's address over at runtime.
# No set_inc, for the siblings' reason: what is recorded there is handed to
# every consumer, and a build tree's paths mean nothing once installed.
my $pkg = ExtUtils::Depends->new('Game::Fanorona');
$pkg->install('include/fn_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;

# EU::Depends hands back an empty LIBS and LDFROM that would clobber
# MakeMaker's own defaults, and an INC that would clobber ours below.
delete @dep{qw(LIBS LDFROM INC)};

# %dep carries its own PM key, which silently stops installing the library if
# it is left to win. Re-add every .pm by hand. A NEW .pm THEREFORE NEEDS
# `perl Makefile.PL` AGAIN, not only `make`.
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# ---- THE PERL FLOOR, AND WHAT IS EVIDENCE FOR IT -----------------------------
#
# 5.014 is the floor, and it is MEASURED: the tarball was built and tested from
# nothing on 5.14.4. Object::Proto::Sugar does not install below it.
#
#   tested, 11 Oct 2026, the tarball from nothing, dependencies from CPAN:
#     5.14.4 and 5.20.3 (threaded), 5.20.2 -DDEBUGGING, 5.22.4, 5.26.3, 5.30.3,
#     5.36.3 plain and threaded, 5.36.3 on i686 with 4-byte integers, 5.40.2
#     with long doubles, 5.40.5, 5.42.3, 5.44.0, all linux; and 5.42.0 on
#     darwin
#   untested: Windows, the BSDs, MSVC, quadmath
#
# The first run of that matrix failed on every perl below 5.30, where an eval
# inside a destructor empties $@ for an exception already on its way out. That
# is why no class here has a DEMOLISH: t/31-exceptions.t.
#
# ---- THE C FLOOR --------------------------------------------------------------
#
# C99, for `unsigned long long` and nothing else: it is the zobrist key. There
# is no -ffp-contract=off probe because THIS ENGINE HAS NO FLOATS.
#
#   measured: fn_engine.c, fn_moves.c, fn_rules.c and fn_search.c compile with no output under -std=c99 -pedantic
#             -Wall -Wextra -Wdeclaration-after-statement, Apple clang,
#             10 Oct 2026
#             and gcc in every image of the matrix above builds all five
#             objects with no warning, 11 Oct 2026
#   untested: MSVC
#
# ---- A REBUILD HAZARD THE SIBLINGS HIT ----------------------------------------
#
# WRITING A .c AND RUNNING make IN THE SAME SECOND CAN LEAVE THE OLD OBJECT
# LINKED. After editing a C file, remove its object AND the linked target:
#
#     rm -f fn_engine.o blib/arch/auto/Game/Fanorona/Fanorona.* && make
#
# A .pm restored in the same second keeps its stale copy in blib:
#
#     sleep 1 && rm -f pm_to_blib && make

if (eval { require ExtUtils::CBuilder; 1 }) {
    my $cb = ExtUtils::CBuilder->new(quiet => 1);
    unless (eval { $cb->have_compiler }) {
        warn <<'NO_CC';

Game::Fanorona is an XS distribution: the whole engine is C and there is no
pure-Perl fallback, so it cannot be installed without a working C compiler.

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
    NAME             => 'Game::Fanorona',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Game/Fanorona.pm',
    EXE_FILES        => ['bin/fanorona'],
    ABSTRACT_FROM    => 'lib/Game/Fanorona.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.014',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'ExtUtils::CBuilder'  => '0',
    },
    TEST_REQUIRES => {
        'FindBin'    => 0,
        'Test::More' => '0.98',
    },
    # Object::Proto is named beside Sugar though no file here says `use
    # Object::Proto`: Sugar 1.00 asks only for 0.19, and under 0.16 a private
    # attribute is not private, so the board's address could be written from
    # outside the class.
    PREREQ_PM => {
        'Carp'                 => 0,
        'Digest::SHA'          => 0,
        'Exporter'             => 0,
        'Getopt::Long'         => 0,
        'Object::Proto'        => '1.00',
        'Object::Proto::Sugar' => '1.00',
        'XSLoader'             => 0,
        'constant'             => 0,
    },

    # The arrow keys need Term::ReadKey. Without it the game is played by typed
    # move, which is everything the tests use, so it is a recommendation.
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs     => { runtime => { recommends => { 'Term::ReadKey' => 0 } } },
    },

    XS     => { 'Fanorona.xs' => 'Fanorona.c' },
    C      => [ 'Fanorona.c', 'fn_engine.c', 'fn_moves.c', 'fn_rules.c', 'fn_search.c' ],
    OBJECT => 'Fanorona$(OBJ_EXT) fn_engine$(OBJ_EXT) fn_moves$(OBJ_EXT) fn_rules$(OBJ_EXT) fn_search$(OBJ_EXT)',
    INC    => '-I. -Iinclude',
    # MakeMaker rescans no header: name it, so the objects rebuild when it
    # moves. Without this a header change produces a build that silently did
    # not happen, and the symptom is a test asserting the old ABI.
    depend => {
        'Fanorona$(OBJ_EXT)'  => 'include/fn_abi.h',
        'fn_engine$(OBJ_EXT)' => 'include/fn_abi.h',
        'fn_moves$(OBJ_EXT)'  => 'include/fn_abi.h',
        'fn_rules$(OBJ_EXT)'  => 'include/fn_abi.h',
        'fn_search$(OBJ_EXT)' => 'include/fn_abi.h',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Game-Fanorona-* Install' },
    %dep,
);

WriteMakefile(%WriteMakefileArgs);
