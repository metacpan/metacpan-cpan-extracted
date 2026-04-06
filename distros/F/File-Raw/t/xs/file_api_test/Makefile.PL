use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# File::Raw exports its C API symbols via dl_load_flags { 0x01 } (RTLD_GLOBAL).
# This means on ELF platforms (Linux, FreeBSD, etc.) we do NOT need to link
# against Raw.so directly - the symbols are globally available at runtime
# as long as File::Raw is loaded first.
#
# On macOS, flat namespace makes symbols visible without any special handling.
# On Windows, we still need explicit linking.

my $extra_libs = '';

if ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys') {
    my $raw_dir = '../../../blib/arch/auto/File/Raw';
    $extra_libs = "-L$raw_dir -lRaw";
}

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
