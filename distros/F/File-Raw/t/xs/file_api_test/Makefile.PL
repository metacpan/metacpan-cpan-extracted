use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# Platform-specific linking against File::Raw shared library
my $extra_libs = '';

if ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'netbsd' ||
    $^O eq 'solaris' || $^O eq 'sunos' || $^O eq 'dragonfly') {
    # Unix ELF systems: link against Raw.so via -L/-l with $ORIGIN rpath
    $extra_libs = '-L../../../blib/arch/auto/File/Raw -Wl,-rpath,\$ORIGIN/../File/Raw -lRaw';
}
elsif ($^O eq 'openbsd') {
    # OpenBSD: link via -L/-l without GNU ld rpath flags
    $extra_libs = '-L../../../blib/arch/auto/File/Raw -lRaw';
}
elsif ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys') {
    my $raw_dir = '../../../blib/arch/auto/File/Raw';
    $extra_libs = "-L$raw_dir -lRaw";
}
# macOS/darwin: no special linking needed (flat namespace makes symbols visible)

my %makefile_args = (
    NAME              => 'file_api_test',
    VERSION           => '0.01',
    PREREQ_PM         => {},
    ABSTRACT          => 'Test module for File::Raw hooks C API',
    AUTHOR            => 'LNATION <email@lnation.org>',
    LICENSE           => 'perl',
    LIBS              => [$extra_libs],
    DEFINE            => '',
    INC               => '-I. -I../../.. -I../../../include',
    C                 => ['file_api_test.c'],
    OBJECT            => 'file_api_test$(OBJ_EXT)',
    OPTIMIZE          => '-O3',
    PM                => { 'file_api_test.pm' => '../../../blib/lib/file_api_test.pm' },
    INST_LIB          => '../../../blib/lib',
    INST_ARCHLIB      => '../../../blib/arch',
);

WriteMakefile(%makefile_args);
