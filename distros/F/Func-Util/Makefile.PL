use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# Platform-specific linker flags for symbol export.
# Other XS modules can use funcutil_callbacks.h to register C-level callbacks.
# Solaris/SunOS use their own native ld (not GNU ld) which rejects
# --export-dynamic; their default behaviour already exports symbols.
my %platform_args;
if ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'openbsd' || $^O eq 'netbsd' ||
    $^O eq 'dragonfly') {
    $platform_args{LDDLFLAGS} = $Config{lddlflags} . ' -Wl,--export-dynamic';
}
elsif ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys') {
    $platform_args{LDDLFLAGS} = ($Config{lddlflags} || '') . ' -Wl,--export-all-symbols';
}

my %WriteMakefileArgs = (
    NAME             => 'Func::Util',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Func/Util.pm',
    ABSTRACT_FROM    => 'lib/Func/Util.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {},
    OBJECT       => 'FuncUtil$(OBJ_EXT)',
    C            => ['FuncUtil.c'],
    XS           => {},
    INC          => '-Iinclude',
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Func-Util-*' },
    %platform_args,
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

# Build the test XS helper module (funcutil_export_test) before running tests
sub MY::postamble {
    return <<'MAKE';
# Build the XS test helper that exercises the C export registry API
# Uses a stamp file to avoid recompiling on every make test
t/xs/funcutil_export_test/.built :: $(INST_DYNAMIC) t/xs/funcutil_export_test/funcutil_export_test.c t/xs/funcutil_export_test/Makefile.PL
	cd t/xs/funcutil_export_test && $(PERLRUN) Makefile.PL && $(MAKE)
	$(NOECHO) $(TOUCH) t/xs/funcutil_export_test/.built

# pure_all is a prerequisite of test_dynamic, so this ensures the helper
# is built after the main module but before the test harness runs
pure_all :: t/xs/funcutil_export_test/.built

clean ::
	-cd t/xs/funcutil_export_test && $(MAKE) clean 2>/dev/null || true
	-$(RM_F) t/xs/funcutil_export_test/.built
MAKE
}
