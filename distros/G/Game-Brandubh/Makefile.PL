use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# ---- Game::Brandubh as an ABI PROVIDER ---------------------------------------
# bd_abi.h publishes the board: squares, the three pieces, the two sides, the
# throne and the corners as geometry, a zobrist key and the position string. It
# is perl-free, so the same C compiles into the XS, into a plain program, or to
# wasm. ExtUtils::Depends installs the header and records the include path;
# Game::Brandubh::Engine::_abi_ptr hands the table's address over at runtime.
# No set_inc, for the siblings' reason: what is recorded there is handed to
# every consumer, and a build tree's paths mean nothing once installed.
my $pkg = ExtUtils::Depends->new('Game::Brandubh');
$pkg->install('include/bd_abi.h');
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
# 5.010 is the SYNTACTIC floor and it is inherited from the siblings rather
# than measured here.
#
#   tested:   perl 5.42.0, darwin-thread-multi-2level, 9 Oct 2026: the whole
#             suite, and the whole suite again with Devel::CallParser 0.004
#             loaded in place of 0.005
#   in part:  perl 5.34.1, darwin-thread-multi-2level, 9 Oct 2026:
#             Game::Brandubh::Notation alone, which needs neither the XS nor
#             Object::Proto::Sugar, and t/13-notation-no-xs.t with it. That
#             perl has no Object::Proto::Sugar, so nothing else could be run
#   inferred: 5.10 upwards, from the syntax alone
#
# The span between the floor and 5.42 IS INFERRED AND HAS NOT BEEN TESTED,
# apart from the one module on 5.34. No older perl was to hand.
#
# ---- THE C FLOOR --------------------------------------------------------------
#
# C99, for `unsigned long long` and nothing else: it is the zobrist key. There
# is no -ffp-contract=off probe because THIS ENGINE HAS NO FLOATS.
#
#   measured: bd_engine.c, bd_moves.c, bd_rules.c and bd_search.c compile with no output under -std=c99 -pedantic
#             -Wall -Wextra, Apple clang 21.0.0, 9 Oct 2026, and with
#             -Wdeclaration-after-statement added
#   untested: gcc proper, and MSVC
#
# THE PERL-FREE CLAIM IS MEASURED TOO: the bd_*.c files compile and link into a
# plain C program with no perl.h and no libperl, and that program prints the
# set-up and its key. Redo it with a ten-line main() and:
#
#   cc -std=c99 -pedantic -Wall -Wextra -Iinclude -o bd main.c bd_engine.c bd_moves.c bd_rules.c bd_search.c
#
# ---- A REBUILD HAZARD THE SIBLING HIT THREE TIMES ----------------------------
#
# WRITING A .c AND RUNNING make IN THE SAME SECOND CAN LEAVE THE OLD OBJECT
# LINKED, and a freshly compiled object landing in the same second as the
# existing bundle skips the LINK. After editing a C file, remove its object AND
# the linked target before building:
#
#     rm -f bd_engine.o blib/arch/auto/Game/Brandubh/Brandubh.* && make
#
# A .pm restored in the same second keeps its stale copy in blib:
#
#     rm -f pm_to_blib && make

if (eval { require ExtUtils::CBuilder; 1 }) {
    my $cb = ExtUtils::CBuilder->new(quiet => 1);
    unless (eval { $cb->have_compiler }) {
        warn <<'NO_CC';

Game::Brandubh is an XS distribution: the whole engine is C and there is no
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
    NAME             => 'Game::Brandubh',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Game/Brandubh.pm',
    ABSTRACT_FROM    => 'lib/Game/Brandubh.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'ExtUtils::CBuilder'  => '0',
    },
    TEST_REQUIRES => {
        'File::Temp'   => 0,
        'FindBin'      => 0,
        'IPC::Open3'   => 0,
        'Scalar::Util' => 0,
        'Symbol'       => 0,
        'Test::More'   => '0.88',
    },
    # Object::Proto::Sugar is the Perl layer: every class with state declares
    # its attributes with `has`. The version is WHAT HAS BEEN RUN and not a
    # known floor: nothing here has been tested against an older one.
    # Object::Proto is named beside it, though no file here says `use
    # Object::Proto`: Sugar 1.00 asks only for 0.19, and under 0.16 a private
    # attribute is not private, so the board's address can be written from
    # outside the class. t/01-board.t fails there and then the process dies.
    # The rest are core, and are declared because they are used: an undeclared
    # use of a core module is noticed only by whoever builds a perl without it.
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

    # ONE ENTRY, and bin/brandubh is the only file in this dist that may call
    # exit: Terminal::start RETURNS a status so that it can be tested.
    EXE_FILES => [ 'bin/brandubh' ],
    # Term::ReadKey is what the arrow keys are read with. Without it the game
    # is played by typing moves, so it is recommended and never required.
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => { runtime => { recommends => { 'Term::ReadKey' => 0 } } },
    },

    XS     => { 'Brandubh.xs' => 'Brandubh.c' },
    C      => [ 'Brandubh.c', 'bd_engine.c', 'bd_moves.c', 'bd_rules.c', 'bd_search.c' ],
    OBJECT => 'Brandubh$(OBJ_EXT) bd_engine$(OBJ_EXT) bd_moves$(OBJ_EXT) bd_rules$(OBJ_EXT) bd_search$(OBJ_EXT)',
    INC    => '-I. -Iinclude',
    # MakeMaker rescans no header: name it, so the objects rebuild when it
    # moves. Without this a header change produces a build that silently did
    # not happen, and the symptom is a test asserting the old ABI.
    depend => {
        'Brandubh$(OBJ_EXT)'  => 'include/bd_abi.h',
        'bd_engine$(OBJ_EXT)' => 'include/bd_abi.h',
        'bd_moves$(OBJ_EXT)'  => 'include/bd_abi.h',
        'bd_rules$(OBJ_EXT)'  => 'include/bd_abi.h',
        'bd_search$(OBJ_EXT)' => 'include/bd_abi.h',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Game-Brandubh-* Install' },
    %dep,
);

WriteMakefile(%WriteMakefileArgs);
