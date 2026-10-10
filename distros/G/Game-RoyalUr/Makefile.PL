use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# ---- Game::RoyalUr as an ABI PROVIDER -----------------------------------------
# ru_abi.h publishes the board: twenty cells, the two hands and homes, the two
# routes as tables, an exact key and the position string. It is perl-free, so
# the same C compiles into the XS, into a plain program, or to wasm.
# ExtUtils::Depends installs the header and records the include path;
# Game::RoyalUr::Engine::_abi_ptr hands the table's address over at runtime.
# No set_inc, for the siblings' reason: what is recorded there is handed to
# every consumer, and a build tree's paths mean nothing once installed.
my $pkg = ExtUtils::Depends->new('Game::RoyalUr');
$pkg->install('include/ru_abi.h');
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
#   tested:   perl 5.42.0, darwin-thread-multi-2level, 9 Oct 2026: the suite
#             as it stands at phase 01
#   inferred: 5.10 upwards, from the syntax alone
#
# The span between the floor and 5.42 IS INFERRED AND HAS NOT BEEN TESTED.
#
# ---- THE C FLOOR --------------------------------------------------------------
#
# C99, for `unsigned long long` and nothing else: it is the key. There is no
# -ffp-contract=off probe because THIS ENGINE HAS NO FLOATS.
#
#   measured: ru_engine.c, ru_moves.c and ru_search.c compile with no output under -std=c99 -pedantic
#             -Wall -Wextra, Apple clang, 9 Oct 2026, and with
#             -Wdeclaration-after-statement added
#   untested: gcc proper, and MSVC
#
# THE PERL-FREE CLAIM IS MEASURED TOO: the ru_*.c files compile and link into a
# plain C program with no perl.h and no libperl, and that program prints both
# routes. Redo it with a short main() and:
#
#   cc -std=c99 -pedantic -Wall -Wextra -Iinclude -o ru main.c ru_engine.c ru_moves.c ru_search.c
#
# ---- A REBUILD HAZARD THE SIBLINGS HIT ----------------------------------------
#
# WRITING A .c AND RUNNING make IN THE SAME SECOND CAN LEAVE THE OLD OBJECT
# LINKED, and a freshly compiled object landing in the same second as the
# existing bundle skips the LINK. After editing a C file, remove its object AND
# the linked target before building:
#
#     rm -f ru_engine.o blib/arch/auto/Game/RoyalUr/RoyalUr.* && make
#
# A .pm restored in the same second keeps its stale copy in blib:
#
#     sleep 1 && rm -f pm_to_blib && make

if (eval { require ExtUtils::CBuilder; 1 }) {
    my $cb = ExtUtils::CBuilder->new(quiet => 1);
    unless (eval { $cb->have_compiler }) {
        warn <<'NO_CC';

Game::RoyalUr is an XS distribution: the whole engine is C and there is no
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
    NAME             => 'Game::RoyalUr',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Game/RoyalUr.pm',
    ABSTRACT_FROM    => 'lib/Game/RoyalUr.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'ExtUtils::CBuilder'  => '0',
    },
    TEST_REQUIRES => {
        'File::Basename' => 0,
        'File::Spec'     => 0,
        'File::Temp'     => 0,
        'FindBin'        => 0,
        'IPC::Open3'     => 0,
        'Scalar::Util'   => 0,
        'Symbol'         => 0,
        'Tie::Hash'      => 0,
        'Test::More'     => '0.98',
    },
    # Object::Proto::Sugar is the Perl layer: every class with state declares
    # its attributes with `has`. The version is WHAT HAS BEEN RUN and not a
    # known floor. Object::Proto is named beside it, though no file here says
    # `use Object::Proto`: Sugar 1.00 asks only for 0.19, and under 0.16 a
    # private attribute is not private, so the board's address can be written
    # from outside the class. Digest::SHA is what the dice are derived with.
    # The rest are core, and are declared because they are used.
    PREREQ_PM => {
        'Carp'                 => 0,
        'Digest::SHA'          => 0,
        'Exporter'             => 0,
        'Object::Proto'        => '1.00',
        'Object::Proto::Sugar' => '1.00',
        'Getopt::Long'         => 0,
        'Scalar::Util'         => 0,
        'XSLoader'             => 0,
        'constant'             => 0,
    },

    # ONE ENTRY, and bin/royalur is the only file in this dist that may call
    # exit: Terminal::start RETURNS a status so that it can be tested.
    EXE_FILES => [ 'bin/royalur' ],
    # Term::ReadKey is what the arrow keys are read with. Without it the game
    # is played by typing moves, so it is recommended and never required.
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => { runtime => { recommends => { 'Term::ReadKey' => 0 } } },
    },

    XS     => { 'RoyalUr.xs' => 'RoyalUr.c' },
    C      => [ 'RoyalUr.c', 'ru_engine.c', 'ru_moves.c', 'ru_search.c' ],
    OBJECT => 'RoyalUr$(OBJ_EXT) ru_engine$(OBJ_EXT) ru_moves$(OBJ_EXT) ru_search$(OBJ_EXT)',
    INC    => '-I. -Iinclude',
    # MakeMaker rescans no header: name it, so the objects rebuild when it
    # moves. Without this a header change produces a build that silently did
    # not happen, and the symptom is a test asserting the old ABI.
    depend => {
        'RoyalUr$(OBJ_EXT)'   => 'include/ru_abi.h',
        'ru_engine$(OBJ_EXT)' => 'include/ru_abi.h',
        'ru_moves$(OBJ_EXT)'  => 'include/ru_abi.h',
        'ru_search$(OBJ_EXT)' => 'include/ru_abi.h',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Game-RoyalUr-* Install' },
    %dep,
);

WriteMakefile(%WriteMakefileArgs);
