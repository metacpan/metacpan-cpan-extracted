use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use Config;

# Make sure Install/ exists for save_config below.
mkdir 'Install' unless -d 'Install';

# Pick up File::Raw's published file_plugin.h via ExtUtils::Depends.
# File::Raw 0.12+ also publishes its Windows import library
# (libRaw.dll.a) via set_libs, so consumers get -L/-lRaw automatically
# without having to hunt for Raw.dll on disk.
my $pkg;
eval { $pkg = ExtUtils::Depends->new('File::Raw::Archive', 'File::Raw') };
if (!$pkg) {
    die "Cannot find File::Raw dependency (need 0.12+).\n"
      . "Install File::Raw 0.12+ or place it as a sibling directory.\n"
        unless -d '../File-Raw/include';
    $pkg = ExtUtils::Depends->new('File::Raw::Archive');
    $pkg->set_inc('-I. -Iinclude -I../File-Raw/include');
} else {
    my %vars = $pkg->get_makefile_vars;
    $pkg->set_inc('-I. -Iinclude ' . ($vars{INC} || ''));
}

# This dist is also a producer: publishes archive_plugin.h for sister
# dists (File::Raw::Archive::Zip, ::Cpio, ::Ar) via ExtUtils::Depends.
$pkg->install('include/archive_plugin.h');

# Platform link recipe.
#
#   Linux/BSD: --export-dynamic so sister archive plugins can resolve
#   our archive_register_plugin etc. via RTLD_GLOBAL at load time;
#   --allow-shlib-undefined so our own link doesn't insist on resolving
#   File::Raw's symbols at link time (they're satisfied at runtime via
#   File::Raw's already-loaded .so).
#
#   Windows: emit a MinGW import library (libArchive.dll.a) alongside
#   Archive.dll. Mirror of File::Raw 0.12's pattern. Sister dists pick
#   it up automatically via the set_libs publish below.
my %platform_args;
if ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'openbsd'
        || $^O eq 'netbsd' || $^O eq 'dragonfly') {
    $platform_args{LDDLFLAGS} = ($Config{lddlflags} || '')
        . ' -Wl,--export-dynamic'
        . ' -Wl,--allow-shlib-undefined'
        . ' -Wl,-soname,Archive.so';
}
elsif ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys') {
    my $implib = 'blib/arch/auto/File/Raw/Archive/libArchive.dll.a';
    $platform_args{LDDLFLAGS} = ($Config{lddlflags} || '')
        . ' -Wl,--export-all-symbols'
        . " -Wl,--out-implib=$implib";
}

# zlib for gzip composition (we talk to libz directly for the
# streaming inflater). On Windows, also publish our own import library
# via set_libs so sister archive plugins (File::Raw::Archive::Zip,
# ::Cpio, ::Ar) get -L/-lArchive automatically when they
# ExtUtils::Depends->new(..., 'File::Raw::Archive').
{
    my $libs = '-lz';
    if ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys') {
        my $arch = $Config{installsitearch};
        $libs .= qq{ -L"$arch/auto/File/Raw/Archive" -lArchive};
    }
    $pkg->set_libs($libs);
}

$pkg->save_config('Install/Files.pm');

my %dep_vars = $pkg->get_makefile_vars;

# Mirror Object::Proto / File::Raw fix: ExtUtils::Depends's PM hash
# overrides MakeMaker's defaults and would skip our .pm file.
$dep_vars{PM}{'lib/File/Raw/Archive.pm'}         = '$(INST_LIB)/File/Raw/Archive.pm';
$dep_vars{PM}{'lib/File/Raw/Archive/Entry.pm'}   = '$(INST_LIB)/File/Raw/Archive/Entry.pm';
$dep_vars{PM}{'lib/File/Raw/Archive/Reader.pm'}  = '$(INST_LIB)/File/Raw/Archive/Reader.pm';
$dep_vars{PM}{'lib/File/Raw/Archive/Writer.pm'}  = '$(INST_LIB)/File/Raw/Archive/Writer.pm';

my %WriteMakefileArgs = (
    NAME             => 'File::Raw::Archive',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/File/Raw/Archive.pm',
    ABSTRACT_FROM    => 'lib/File/Raw/Archive.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'File::Raw'           => '0.12',
    },
    TEST_REQUIRES => {
        'Test::More'         => '0',
        'Archive::Tar'       => '0',
        'IO::Compress::Gzip' => '0',
    },
    PREREQ_PM => {
        'File::Raw'       => '0.12',
        'File::Raw::Gzip' => '0.01',
    },
    OBJECT => 'Archive$(OBJ_EXT) arch_io$(OBJ_EXT) tar$(OBJ_EXT) extract$(OBJ_EXT) marshal$(OBJ_EXT)',
    C      => ['arch_io.c', 'tar.c', 'extract.c', 'marshal.c'],
    XS     => { 'Archive.xs' => 'Archive.c' },
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean  => { FILES => 'File-Raw-Archive-* Archive.c Archive.o arch_io.o tar.o extract.o marshal.o Install/Files.pm' },
    %platform_args,
    %dep_vars,
);

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
