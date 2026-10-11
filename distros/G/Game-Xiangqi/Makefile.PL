use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

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
    PREREQ_PM => {
        'Digest::SHA'          => 0,
        'Object::Proto::Sugar' => '0.06',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            runtime => {
                recommends => {
                    'Term::ReadKey' => '0',
                },
            },
        },
    },
    EXE_FILES => [ 'bin/xiangqi' ],
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
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
