use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use Config;

# An in-house XML 1.0 + Namespaces parser with Canonical XML, written for
# consumers that verify signatures over the canonical form. XS, entirely:
# the parser, the arena tree and the serialiser are C headers under
# include/frx/, compiled into one translation unit through XML.xs, and the
# Perl surface is thin XSUBs over the same functions the C ABI table
# points at. No libxml2, no vendored parser: the safe subset of XML is
# small and owning it is cheaper than fencing a library whose defaults
# resolve entities.
#
# Consumer of File::Raw (file_plugin.h for the `xml` plugin, file_chunk.h
# for Reader->from_file) and provider of frx_abi.h, both through
# ExtUtils::Depends, the File-Raw-JSON shape.

my $pkg;
eval { $pkg = ExtUtils::Depends->new('File::Raw::XML', 'File::Raw'); };
if (!$pkg) {
    die "Cannot find the File::Raw dependency.\n"
      . "Install File::Raw 0.17+, or place it as a sibling directory.\n"
        unless -d '../File-Raw/include';
    $pkg = ExtUtils::Depends->new('File::Raw::XML');
    $pkg->set_inc('-I. -Iinclude -I../File-Raw/include');
} else {
    my %vars = $pkg->get_makefile_vars;
    $pkg->set_inc('-I. -Iinclude ' . ($vars{INC} || ''));
}

# Provider side: install the public C ABI header so XS consumers reach it
# through ExtUtils::Depends - no vendoring, no copying. save_config writes
# File/Raw/XML/Install/Files.pm recording the include dir for dependents.
$pkg->install('include/frx_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

# As a provider, get_makefile_vars now returns a PM map (to install
# frx_abi.h and Files.pm) which REPLACES MakeMaker's auto-detected PM - so
# re-add the module's own .pm files, exactly as File::Raw::JSON does.
my %dep_vars = $pkg->get_makefile_vars;
$dep_vars{PM}{'lib/File/Raw/XML.pm'} = '$(INST_LIB)/File/Raw/XML.pm';
$dep_vars{PM}{'lib/File/Raw/XML/Document.pm'}
    = '$(INST_LIB)/File/Raw/XML/Document.pm';
$dep_vars{PM}{'lib/File/Raw/XML/Node.pm'}
    = '$(INST_LIB)/File/Raw/XML/Node.pm';
$dep_vars{PM}{'lib/File/Raw/XML/Reader.pm'}
    = '$(INST_LIB)/File/Raw/XML/Reader.pm';
$dep_vars{PM}{'lib/File/Raw/XML/XPath.pm'}
    = '$(INST_LIB)/File/Raw/XML/XPath.pm';
$dep_vars{PM}{'lib/File/Raw/XML/Attr.pm'}
    = '$(INST_LIB)/File/Raw/XML/Attr.pm';
$dep_vars{PM}{'lib/File/Raw/XML/Namespace.pm'}
    = '$(INST_LIB)/File/Raw/XML/Namespace.pm';

# A provider of a function-pointer table resolved through _abi_ptr exports
# no symbol, so this is the consumer-side link recipe (File::Raw::Hash's),
# not File::Raw::Archive's --export-dynamic one.
my %platform_args;
if ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'openbsd'
        || $^O eq 'netbsd' || $^O eq 'dragonfly') {
    # GNU ld: allow unresolved syms, satisfied at runtime by RTLD_GLOBAL.
    $platform_args{dynamic_lib} = {
        OTHERLDFLAGS => '-Wl,--allow-shlib-undefined'
    };
}
# Windows / Cygwin / msys: nothing to do here. File::Raw 0.13+ ships a
# MinGW import library and publishes its location via set_libs, which
# flows in through get_makefile_vars above.

# MakeMaker tracks neither an included header nor an INCLUDEd .xs, so an
# edit there would not rebuild without these. The globs run at configure
# time: re-run Makefile.PL after adding a file.
my $xs_deps = join ' ', glob('xs/*.xs');
my $h_deps  = join ' ', 'include/frx_abi.h', glob('include/frx/*.h');

my %WriteMakefileArgs = (
    NAME             => 'File::Raw::XML',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/File/Raw/XML.pm',
    ABSTRACT_FROM    => 'lib/File/Raw/XML.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010000',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        # 0.17 is where file_chunk.h arrives, and Reader->from_file calls
        # file_chunk_open/read/close: there is no older version this
        # builds against. The floor is a header that has to be there, not
        # a comparison this time.
        'File::Raw'           => '0.17',   # file_plugin.h, file_chunk.h
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    # t/15-leak.t's two gates, each skipping by name without its module.
    # Suggested rather than required: a smoker that installs them runs the
    # gates, and one whose platform cannot build Proc::ProcessTable still
    # installs this dist, which needs neither at runtime.
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            test => {
                suggests => {
                    'Test::LeakTrace'     => '0',
                    'Proc::ProcessTable'  => '0',
                },
            },
        },
    },
    PREREQ_PM => {
        'File::Raw' => '0.17',
    },
    XS     => { 'XML.xs' => 'XML.c' },
    OBJECT => 'XML$(OBJ_EXT)',
    # The W3C conformance suite runs under `make test` like everything
    # else. MakeMaker's default is t/*.t, which does not descend, and the
    # runner lives in t/xmlconf/ beside the fetched suite; without the
    # suite it skips by name, so a smoker sees a skip and a developer who
    # has run tools/xmlconf/fetch.sh sees the partitions.
    test   => { TESTS => 't/*.t t/xmlconf/*.t' },
    depend => {
        'XML.c'         => $xs_deps,
        'XML$(OBJ_EXT)' => $h_deps,
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => {
        FILES => 'File-Raw-XML-* XML.c XML.o XML.bs Install/Files.pm'
    },
    %platform_args,
    %dep_vars,
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

# the spec 2 prereqs structure META_MERGE carries needs 6.57_02; older
# MakeMaker would write it through unchanged and produce invalid META
delete $WriteMakefileArgs{META_MERGE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.57_02'); 1 };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
