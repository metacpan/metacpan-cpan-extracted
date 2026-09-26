use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# ---- Game::Xiangqi as an ABI PROVIDER ----------------------------------------
# xq_abi.h publishes the board: points, pieces, the palace and the river as
# geometry, a packed move, do and undo, a zobrist key and FEN. It is perl-free,
# so the same C compiles into the XS, into a plain program, or to wasm.
# ExtUtils::Depends installs the header and records the include path;
# Game::Xiangqi::Engine::_abi_ptr hands the table's address over at runtime. No
# set_inc, for the sibling's reason: what is recorded there is handed to every
# consumer, and a build tree's paths mean nothing once installed.
my $pkg = ExtUtils::Depends->new('Game::Xiangqi');
$pkg->install('include/xq_abi.h');
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
# 5.010 is the SYNTACTIC floor and it is inherited from the sibling rather than
# measured here: nothing in this distribution yet uses anything later, and
# nothing has been run on an older perl than the two named below.
#
#   tested:   the perl this was built on, 25 Sep 2026
#   inferred: 5.10 upwards, from the syntax alone
#
# The span between the floor and the oldest tested perl IS INFERRED AND HAS NOT
# BEEN TESTED. Saying so is the point of this comment. Phase 11 runs the suite
# on a second perl and rewrites these two lines with what it found.
#
# ---- AND THE FLOOR NOBODY WRITES DOWN: THE COMPILER --------------------------
#
# There is deliberately no -ffp-contract=off probe here: the ball engine needs
# one because its doubles must round identically on every platform, and THIS
# ENGINE HAS NO FLOATS. Copying the probe over would be cargo.
#
# THE C FLOOR IS C99, NOT THE C89 THE PLAN ASKED FOR, AND THAT WAS MEASURED
# RATHER THAN ASSUMED. xq_engine.c compiles with NO output at all under
# -std=c99, c11 and c17, each with -pedantic -Wall -Wextra.
#
# C89 is the one that is not clean, and it is worth naming what makes it so:
# seventeen diagnostics, EVERY ONE of them
#
#     include/xq_abi.h:151: warning: 'long long' is an extension when C99 mode
#                           is not enabled [-Wlong-long]
#
# which is the zobrist key and nothing else. Lowering the floor would mean
# carrying the key as two 32-bit halves through a published interface, which is
# an ABI decision and not a build-system one. The plan file's "C89 declarations
# at the top of a block" is still followed as a style, because it costs nothing
# and it keeps that option open.
#
#   tested:   Apple clang 17.0.0, 25 Sep 2026
#   untested: gcc proper, and MSVC. /usr/bin/gcc on this machine IS clang,
#             which is not a second compiler however it is spelled.
#
# AND THE PERL-FREE CLAIM IS MEASURED TOO, because a header that says so and is
# not is the worst kind of documentation. xq_engine.c compiles and links into a
# plain C program with no perl.h, no -I to a CORE directory and no libperl, and
# that program prints the opening FEN. Redo it with:
#
#   cc -std=c99 -pedantic -Wall -Wextra -Iinclude -o /tmp/xq /tmp/xqmain.c xq_engine.c

# ---- A REBUILD HAZARD THIS DIST HAS HIT THREE TIMES, 25 Sep 2026 ------------
#
# WRITING A .c AND RUNNING make IN THE SAME SECOND CAN LEAVE THE OLD OBJECT
# LINKED. make compares the object's timestamp against the source's, and when
# both land in the same second it decides the object is current. The build says
# nothing, the tests run against the previous code, and the result is a lie in
# whichever direction that code happened to go.
#
# It cost two wrong conclusions here: a mutation reported as "not caught" when
# the mutation was never built, and a ruling reported as rule 34 when the built
# code said 18. Both looked like real findings.
#
# THE THIRD TIME IT WAS THE LINK STEP AND NOT THE COMPILE, and removing the
# object was not enough. A phase 09 mutation harness did `rm -f xq_search.o &&
# make` faithfully, and still reported five of seven mutations as NOT CAUGHT. Every
# one of those five was a lie: the freshly compiled object landed in the SAME SECOND
# as the existing .bundle, make saw a target no older than its prerequisite, skipped
# the LINK entirely, and the tests ran against the previous build. The first two
# mutations were caught only because the bundle happened to be a minute old when the
# harness started.
#
# SO: after editing a C file, remove its object AND THE LINKED TARGET before
# building.
#
#     rm -f xq_judge.o blib/arch/auto/Game/Xiangqi/Xiangqi.bundle && make
#
# The extension is .bundle on darwin and .so elsewhere, so a harness that has to run
# anywhere globs for it rather than naming it. A mutation harness must do this
# between every mutation, or it measures nothing at all, and it will tell you so in
# the most convincing possible way: by agreeing with you.
#
# IT APPLIES TO .pm FILES TOO, and the fix there is different. lib/*.pm is
# copied into blib/ under the control of the pm_to_blib STAMP FILE, so a .pm
# restored in the same second keeps its stale copy in blib and removing the
# blib copy alone does nothing: make sees the stamp is current and does not
# copy again. Found the same afternoon, on Notation.pm, with the source clean
# and blib still carrying the mutation.
#
#     rm -f pm_to_blib && make

if (eval { require ExtUtils::CBuilder; 1 }) {
    my $cb = ExtUtils::CBuilder->new(quiet => 1);
    unless (eval { $cb->have_compiler }) {
        warn <<'NO_CC';

Game::Xiangqi is an XS distribution: the whole engine is C and there is no
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
    NAME             => 'Game::Xiangqi',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Game/Xiangqi.pm',
    ABSTRACT_FROM    => 'lib/Game/Xiangqi.pm',
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
    # TWO, and each has a reason written down.
    #
    # Digest::SHA: the bot draws its rung and its tie-break from the game's seed,
    # and two workers in a pool must agree about both. It is CORE, so it is there
    # already, and that is exactly why an undeclared use of it would never be
    # noticed until somebody built a perl without it.
    #
    # Object::Proto::Sugar: the Perl layer. Every class but Notation declares its
    # attributes with `has`, so this is a load-time dependency of the facade, the
    # engine wrapper, the terminal and the refusals, not an optional nicety. The
    # version is WHAT HAS BEEN RUN and not a known floor: nothing here has been
    # tested against an older one.
    PREREQ_PM => {
        'Digest::SHA'          => 0,
        'Object::Proto::Sugar' => '0.06',
    },
    # ONE ENTRY, and bin/xiangqi is the only file in this dist that may call
    # exit: Terminal::start RETURNS a status so that it can be tested.
    EXE_FILES => [ 'bin/xiangqi' ],

    XS     => { 'Xiangqi.xs' => 'Xiangqi.c' },
    C      => [ 'Xiangqi.c', 'xq_engine.c', 'xq_moves.c', 'xq_mate.c', 'xq_judge.c', 'xq_search.c' ],
    OBJECT => 'Xiangqi$(OBJ_EXT) xq_engine$(OBJ_EXT) xq_moves$(OBJ_EXT) xq_mate$(OBJ_EXT) xq_judge$(OBJ_EXT) xq_search$(OBJ_EXT)',
    INC    => '-I. -Iinclude',
    # MakeMaker rescans no header: name it, so the objects rebuild when it
    # moves. Without this a header change produces a build that silently did
    # not happen, and the symptom is a test asserting the old ABI.
    depend => {
        'Xiangqi$(OBJ_EXT)'   => 'include/xq_abi.h',
        'xq_engine$(OBJ_EXT)' => 'include/xq_abi.h',
        'xq_moves$(OBJ_EXT)'  => 'include/xq_abi.h',
        'xq_mate$(OBJ_EXT)'   => 'include/xq_abi.h',
        'xq_judge$(OBJ_EXT)'  => 'include/xq_abi.h',
        'xq_search$(OBJ_EXT)' => 'include/xq_abi.h',
    },
    clean => { FILES => 'Game-Xiangqi-* Install' },
    %dep,
);

WriteMakefile(%WriteMakefileArgs);
