use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

my $pkg = ExtUtils::Depends->new('Game::Shogi');
$pkg->install('include/shg_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;

delete @dep{qw(LIBS LDFROM INC)};

File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

if (eval { require ExtUtils::CBuilder; 1 }) {
    my $cb = ExtUtils::CBuilder->new(quiet => 1);
    unless (eval { $cb->have_compiler }) {
        warn <<'NO_CC';

Game::Shogi is an XS distribution: the whole engine is C and there is no
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
    NAME             => 'Game::Shogi',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Game/Shogi.pm',
    ABSTRACT_FROM    => 'lib/Game/Shogi.pm',
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
    PREREQ_PM => {
        'Carp'                 => 0,
        'Digest::SHA'          => 0,
        'Exporter'             => 0,
        'Game::Terminal::Kit'  => '0.05',
        'Getopt::Long'         => 0,
        'IO::Handle'           => 0,
        'Object::Proto'        => '1.00',
        'Object::Proto::Sugar' => '1.00',
        'XSLoader'             => 0,
        'constant'             => 0,
    },

    EXE_FILES => ['bin/shogi'],
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => { runtime => { recommends => { 'Term::ReadKey' => 0 } } },
    },

    macro  => { TARFLAGS => "--format=ustar -c -v -f" },
    XS     => { 'Shogi.xs' => 'Shogi.c' },
    C      => [ 'Shogi.c', 'shg_engine.c', 'shg_moves.c', 'shg_mate.c', 'shg_judge.c', 'shg_search.c' ],
    OBJECT => 'Shogi$(OBJ_EXT) shg_engine$(OBJ_EXT) shg_moves$(OBJ_EXT) shg_mate$(OBJ_EXT) shg_judge$(OBJ_EXT) shg_search$(OBJ_EXT)',
    INC    => '-I. -Iinclude',
    depend => {
        'Shogi$(OBJ_EXT)'      => 'include/shg_abi.h',
        'shg_engine$(OBJ_EXT)' => 'include/shg_abi.h shg_internal.h',
        'shg_moves$(OBJ_EXT)'  => 'include/shg_abi.h shg_internal.h',
        'shg_mate$(OBJ_EXT)'   => 'include/shg_abi.h shg_internal.h',
        'shg_judge$(OBJ_EXT)'  => 'include/shg_abi.h shg_internal.h',
        'shg_search$(OBJ_EXT)' => 'include/shg_abi.h shg_internal.h',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Game-Shogi-* Install' },
    %dep,
);

WriteMakefile(%WriteMakefileArgs);
