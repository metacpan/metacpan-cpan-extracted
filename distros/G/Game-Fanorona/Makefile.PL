use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

my $pkg = ExtUtils::Depends->new('Game::Fanorona');
$pkg->install('include/fn_abi.h');
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
    PREREQ_PM => {
        'Carp'                 => 0,
        'Digest::SHA'          => 0,
        'Exporter'             => 0,
        'Getopt::Long'         => 0,
        'Object::Proto'        => '1.00',
        'Game::Terminal::Kit'  => '0.05',
        'Object::Proto::Sugar' => '1.00',
        'XSLoader'             => 0,
        'constant'             => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs     => { runtime => { recommends => { 'Term::ReadKey' => 0 } } },
    },

    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    XS     => { 'Fanorona.xs' => 'Fanorona.c' },
    C      => [ 'Fanorona.c', 'fn_engine.c', 'fn_moves.c', 'fn_rules.c', 'fn_search.c' ],
    OBJECT => 'Fanorona$(OBJ_EXT) fn_engine$(OBJ_EXT) fn_moves$(OBJ_EXT) fn_rules$(OBJ_EXT) fn_search$(OBJ_EXT)',
    INC    => '-I. -Iinclude',
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
