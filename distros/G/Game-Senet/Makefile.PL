use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# ---- Game::Senet as an ABI PROVIDER -------------------------------------------
# sen_abi.h publishes the board: thirty houses, the side to move, the grid, the
# marked houses, the named rule sets as data, an exact key and the position
# string. It is perl-free, so the same C compiles into the XS, into a plain
# program, or to wasm. ExtUtils::Depends installs the header and records the
# include path; Game::Senet::Engine::_abi_ptr hands the table's address over at
# runtime. No set_inc, for the siblings' reason: what is recorded there is
# handed to every consumer, and a build tree's paths mean nothing once
# installed.
my $pkg = ExtUtils::Depends->new('Game::Senet');
$pkg->install('include/sen_abi.h');
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

# ---- THE PERL FLOOR -----------------------------------------------------------
#
# 5.014, as Game::RoyalUr measured on 13 Oct 2026: Object::Proto::Sugar does not
# install below it (5.10.1 stops at Devel::CallParser 0.006, 5.12.5 at
# BEGIN::Lift). The modules say `use 5.010` and the C avoids what 5.10.0 lacks
# (HeUTF8, mPUSHs, mXPUSHs; and SvNV_nomg, isWORDCHAR, G_LIST of later perls,
# grepped for on 18 Oct 2026 and absent), so the floor can follow Sugar's if
# Sugar's ever falls. Run here: 5.42 only; the Docker matrix is the judge of
# the rest.
#
# ---- THE C FLOOR --------------------------------------------------------------
#
# C99, for `unsigned long long` and nothing else: it is the key. There is no
# -ffp-contract=off probe because THIS ENGINE HAS NO FLOATS.
#
# Checked 18 Oct 2026, the three engine files each with
#
#     cc -std=c99 -pedantic -Wall -Wextra -Wdeclaration-after-statement
#
# and not one warning; Senet.c's fourteen under -Wdeclaration-after-statement
# are all in perl's own inline.h. No -std= is forced on the user's compiler.
#
# ---- A REBUILD HAZARD THE SIBLINGS HIT ----------------------------------------
#
# WRITING A .c AND RUNNING make IN THE SAME SECOND CAN LEAVE THE OLD OBJECT
# LINKED. After editing a C file, remove its object AND the linked target:
#
#     rm -f sen_engine.o blib/arch/auto/Game/Senet/Senet.* && make
#
# A .pm restored in the same second keeps its stale copy in blib:
#
#     sleep 1 && rm -f pm_to_blib && make

if (eval { require ExtUtils::CBuilder; 1 }) {
    my $cb = ExtUtils::CBuilder->new(quiet => 1);
    unless (eval { $cb->have_compiler }) {
        warn <<'NO_CC';

Game::Senet is an XS distribution: the whole engine is C and there is no
pure-Perl fallback, so it cannot be installed without a working C compiler.

  Debian, Ubuntu    apt-get install build-essential
  RedHat, Fedora    dnf group install "Development Tools"
  macOS             xcode-select --install
  Windows           Strawberry Perl already has one; ActivePerl needs MSVC

Nothing else is missing. Install a compiler and run this again.

NO_CC
        exit 0;
    }
}

my %WriteMakefileArgs = (
    NAME             => 'Game::Senet',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Game/Senet.pm',
    ABSTRACT_FROM    => 'lib/Game/Senet.pm',
    LICENSE          => 'artistic_2',
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    MIN_PERL_VERSION => '5.014',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'ExtUtils::CBuilder'  => '0',
    },
    TEST_REQUIRES => {
        'File::Spec'  => 0,
        'File::Temp'  => 0,
        'FindBin'     => 0,
        'IPC::Open3'  => 0,
        'Symbol'      => 0,
        'Test::More'  => '0.98',
        'Tie::Hash'   => 0,
        'Time::HiRes' => 0,
    },
    # Object::Proto::Sugar is the Perl layer. The versions are WHAT HAS BEEN
    # RUN and not a known floor. Object::Proto is named beside it because under
    # 0.16 a private attribute is not private, so the board's address could be
    # written from outside the class. Digest::SHA derives the sticks from the
    # seed.
    PREREQ_PM => {
        'Carp'                 => 0,
        'Digest::SHA'          => 0,
        'Exporter'             => 0,
        'Game::Terminal::Kit'  => '0.05',
        'Getopt::Long'         => 0,
        'Object::Proto'        => '1.00',
        'Object::Proto::Sugar' => '1.00',
        'Scalar::Util'         => 0,
        'XSLoader'             => 0,
        'constant'             => 0,
    },

    EXE_FILES => [ 'bin/senet' ],
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => { runtime => { recommends => { 'Term::ReadKey' => 0 } } },
    },

    XS     => { 'Senet.xs' => 'Senet.c' },
    C      => [ 'Senet.c', 'sen_engine.c', 'sen_moves.c', 'sen_search.c' ],
    OBJECT => 'Senet$(OBJ_EXT) sen_engine$(OBJ_EXT) sen_moves$(OBJ_EXT) sen_search$(OBJ_EXT)',
    INC    => '-I. -Iinclude',
    # MakeMaker rescans no header: name it, so the objects rebuild when it
    # moves. Without this a header change produces a build that silently did
    # not happen, and the symptom is a test asserting the old ABI.
    depend => {
        'Senet$(OBJ_EXT)'      => 'include/sen_abi.h',
        'sen_engine$(OBJ_EXT)' => 'include/sen_abi.h',
        'sen_moves$(OBJ_EXT)'  => 'include/sen_abi.h',
        'sen_search$(OBJ_EXT)' => 'include/sen_abi.h',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Game-Senet-* Install' },
    %dep,
);

WriteMakefile(%WriteMakefileArgs);
