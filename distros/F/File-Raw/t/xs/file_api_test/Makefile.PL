use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# File::Raw exports its C API via dl_load_flags { 0x01 } (RTLD_GLOBAL) on ELF
# platforms; macOS uses flat namespace. On both, the test extension's undefined
# references to file_set_read_hook() etc. resolve at runtime against Raw.so,
# so no explicit linking is needed.
#
# On Windows / Cygwin we don't ship an import library for Raw.dll, so
# file_api_test.c #includes "file_hooks_impl.h" under #ifdef _WIN32/__CYGWIN__
# to get a private copy of the hook implementation. The cross-DLL subtests in
# t/012-file-xs-api.t skip on those platforms (each DLL ends up with its own
# hook state).

my %makefile_args = (
    NAME              => 'file_api_test',
    VERSION           => '0.01',
    PREREQ_PM         => {},
    ABSTRACT          => 'Test module for File::Raw hooks C API',
    AUTHOR            => 'LNATION <email@lnation.org>',
    LICENSE           => 'perl',
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
