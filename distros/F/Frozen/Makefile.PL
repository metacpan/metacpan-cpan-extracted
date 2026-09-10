use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# Frozen.xs sits at the top of the dist and the build is the plain
# single-extension one MakeMaker defaults to. An XSMULTI build from
# lib/Frozen.xs writes its linker export list to lib/Frozen.def, while the
# import-library rule Strawberry adds for MinGW reads $(EXPORT_LIST), which is
# always $(BASEEXT).def in the top directory - the two names never met and
# dlltool failed the build (CPAN Testers, 5.42 Strawberry).

# ---- Frozen as an ABI PROVIDER ------------------------------------------- *
# fz_abi.h publishes the reader so a consumer's XS can open a frozen file and
# walk it without a Perl frame - which is the whole point, since a consumer
# paying a method call per lookup would be slower than the flat block it is
# replacing. ExtUtils::Depends installs the header and records the include
# path; Frozen::_abi_ptr hands over the table's address at runtime.
#
# Provider only: Frozen consumes nobody's ABI and has no runtime prerequisites.
#
# NO set_inc. What EU::Depends records there is handed to every consumer, and
# a provider's own build-tree paths are meaningless once installed: '-I.' in a
# consumer's compile line means the CONSUMER's directory, and '-Iinclude'
# means a directory that is very likely not there. A consumer needs exactly
# one path - the installed header's - and EU::Depends derives that from CORE
# by itself. Apophis records inc => '' for this reason; providers that call
# set_inc here have shipped absolute paths from the author's home directory
# in Install/Files.pm.
my $pkg = ExtUtils::Depends->new('Frozen');
$pkg->install('include/fz_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;
# EU::Depends hands back an empty LIBS/LDFROM that would clobber MakeMaker's
# defaults, and an INC of its own. Frozen sets INC itself below and links
# nothing extra.
delete @dep{qw(LIBS LDFROM INC)};

# Its PM map REPLACES MakeMaker's auto-detected one, so everything under lib/
# has to be re-added by hand or it silently stops being installed.
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# MakeMaker maps Frozen.xs -> Frozen.c and rescans neither the INCLUDEd xs/
# fragments nor the C headers, so name both: regenerate Frozen.c when a
# fragment changes, and rebuild the object when a header does. The globs run
# at CONFIGURE time - re-run Makefile.PL after adding a file.
my $xs_deps = join ' ', glob('xs/*.xs');
my $h_deps  = join ' ', 'include/fz_abi.h', glob('include/fz/*.h');

my %WriteMakefileArgs = (
    NAME             => 'Frozen',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Frozen.pm',
    ABSTRACT_FROM    => 'lib/Frozen.pm',
    LICENSE          => 'artistic_2',
    # 5.010 rather than the skeleton's 5.008003: the format is uint32_t
    # throughout and <stdint.h> is the floor that buys.
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {},
    XS     => { 'Frozen.xs' => 'Frozen.c' },
    OBJECT => 'Frozen$(OBJ_EXT)',
    INC    => '-I. -Iinclude',
    depend => {
        'Frozen.c'         => $xs_deps,
        'Frozen$(OBJ_EXT)' => $h_deps,
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Frozen-* Install/Files.pm' },
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
