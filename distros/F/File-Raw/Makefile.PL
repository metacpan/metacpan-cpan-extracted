use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use Config;

my %platform_args;
if ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'netbsd' ||
    $^O eq 'dragonfly') {
    $platform_args{LDDLFLAGS} = $Config{lddlflags} . ' -Wl,--export-dynamic -Wl,-soname,Raw.so';
}
elsif ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys') {
    my $implib = 'blib/arch/auto/File/Raw/libRaw.dll.a';
    $platform_args{LDDLFLAGS} = ($Config{lddlflags} || '')
        . ' -Wl,--export-all-symbols'
        . " -Wl,--out-implib=$implib";
}

my $pkg = ExtUtils::Depends->new('File::Raw');
$pkg->set_inc('-I. -Iinclude');
$pkg->install('include/file_plugin.h');

if ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys') {
    my $arch = $Config{installsitearch};
    $pkg->set_libs(qq{-L"$arch/auto/File/Raw" -lRaw});
}

mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');
my %dep_vars = $pkg->get_makefile_vars;

$dep_vars{PM}{'lib/File/Raw.pm'} = '$(INST_LIB)/File/Raw.pm';

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
        'ExtUtils::Depends'   => '0.404',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
    },
    OBJECT       => 'file$(OBJ_EXT)',
    C            => ['file.c'],
    XS           => {},
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean        => { FILES => 'File-Raw-* Install/Files.pm' },
    %platform_args,
    # ExtUtils::Depends provides INC (with our set_inc above) and the
    # PM rules for installing file_plugin.h + Install/Files.pm to
    # .../File/Raw/Install/. Our own lib/File/Raw.pm is wired in above.
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

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
