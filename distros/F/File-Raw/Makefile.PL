use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# Platform-specific linker flags for symbol export
my %platform_args;
if ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'netbsd' ||
    $^O eq 'solaris' || $^O eq 'sunos' || $^O eq 'dragonfly') {
    $platform_args{LDDLFLAGS} = $Config{lddlflags} . ' -Wl,--export-dynamic -Wl,-soname,Raw.so';
}
elsif ($^O eq 'openbsd') {
    # OpenBSD ld does not support --export-dynamic or -soname (not GNU ld)
    $platform_args{LDDLFLAGS} = $Config{lddlflags};
}
elsif ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys') {
    $platform_args{LDDLFLAGS} = ($Config{lddlflags} || '') . ' -Wl,--export-all-symbols';
}

my %WriteMakefileArgs = (
    NAME             => 'File::Raw',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/File/Raw.pm',
    ABSTRACT_FROM    => 'lib/File/Raw.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
    },
    OBJECT       => 'file$(OBJ_EXT)',
    C            => ['file.c'],
    XS           => {},
    INC          => '-I. -Iinclude',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean        => { FILES => 'File-Raw-*' },
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

package MY;

sub postamble {
    return <<'MAKE_FRAG';
build_test_xs : $(INST_DYNAMIC)
	cd t/xs/file_api_test && $(PERL) Makefile.PL $(PASTHRU) && $(MAKE) $(PASTHRU)

all :: build_test_xs
MAKE_FRAG
}
