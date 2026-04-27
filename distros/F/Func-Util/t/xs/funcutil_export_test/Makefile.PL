use strict;
use warnings;
# WriteEmptyMakefile is in @EXPORT_OK, not @EXPORT — without the explicit
# import the Windows/Cygwin skip-branch below dies with
# "Undefined subroutine &main::WriteEmptyMakefile".
use ExtUtils::MakeMaker qw(WriteMakefile WriteEmptyMakefile);
use Config;

# Skip building this test helper entirely on Windows/Cygwin: linking
# against Util.dll requires an import library we don't ship, the runtime
# load fails ("No such process"), and the failed dlopen poisons Cygwin
# fork resources for later tests in the run. The corresponding test
# (t/011-util-export-registry-xs.t) skips on those platforms.
if ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys') {
    WriteEmptyMakefile(
        NAME    => 'funcutil_export_test',
        VERSION => '0.01',
    );
    exit 0;
}

# Platform-specific linking against Func::Util shared library.
# Func::Util uses DynaLoader with RTLD_GLOBAL, so its symbols are globally
# visible at runtime. We just need the build-time linker to accept unresolved
# symbols that will be satisfied by RTLD_GLOBAL at load time.
my $extra_libs = '';
my $extra_ldfrom = '';
my $extra_ldflags = '';

if ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'openbsd' || $^O eq 'netbsd' ||
    $^O eq 'solaris' || $^O eq 'sunos' || $^O eq 'dragonfly') {
    # Don't link against Util.so directly - that records a DT_NEEDED with a
    # relative path that the runtime linker can't resolve. Instead, allow
    # unresolved symbols at link time; they'll be satisfied by RTLD_GLOBAL.
    $extra_ldflags = '-Wl,--allow-shlib-undefined';
}
# macOS/darwin: no special linking needed (flat namespace + RTLD_GLOBAL)

my %makefile_args = (
    NAME              => 'funcutil_export_test',
    VERSION           => '0.01',
    PREREQ_PM         => {},
    ABSTRACT          => 'Test module for Func::Util export registry C API',
    AUTHOR            => 'LNATION <email@lnation.org>',
    LICENSE           => 'perl',
    LIBS              => [$extra_libs],
    DEFINE            => '',
    INC               => '-I. -I../../../include',
    C                 => ['funcutil_export_test.c'],
    OBJECT            => 'funcutil_export_test$(OBJ_EXT)',
    OPTIMIZE          => '-O3',
    LIB               => '../../../blib/lib',
    INST_LIB          => '../../../blib/lib',
    INST_ARCHLIB      => '../../../blib/arch',
);

# On Windows/Cygwin, must link against Func::Util .dll directly
if ($extra_ldfrom) {
    $makefile_args{OBJECT} = "funcutil_export_test\$(OBJ_EXT) $extra_ldfrom";
}

# On Linux/ELF, allow unresolved symbols (satisfied at runtime by RTLD_GLOBAL)
if ($extra_ldflags) {
    $makefile_args{dynamic_lib} = { OTHERLDFLAGS => $extra_ldflags };
}

WriteMakefile(%makefile_args);
