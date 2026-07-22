use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Path qw(make_path);
use Cwd qw(abs_path);
use Config;

make_path('lib/Font/Metrics/Install');

my @c_src = sort glob('fm_*.c');

my $pkg = ExtUtils::Depends->new('Font::Metrics');
$pkg->set_inc(join ' ', map { "-I$_" } abs_path('.'), abs_path('include'));
$pkg->set_libs('');
$pkg->add_c(@c_src);
$pkg->save_config('lib/Font/Metrics/Install/Files.pm');

my %deps = $pkg->get_makefile_vars();

my %WriteMakefileArgs = (
    NAME             => 'Font::Metrics',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Font/Metrics.pm',
    ABSTRACT_FROM    => 'lib/Font/Metrics.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    macro            => { TARFLAGS => '--format=ustar -c -v -f' },
    CCFLAGS          => "$Config{ccflags}",
    XS               => { 'Metrics.xs' => 'Metrics.c' },
    INC              => $deps{INC},
    C                => ['Metrics.c', @c_src],
    OBJECT           => join(' ', 'Metrics$(OBJ_EXT)',
                                  map { (my $o = $_) =~ s/\.c$/\$(OBJ_EXT)/; $o }
                                      @c_src),
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.302',
    },
    TEST_REQUIRES => {
        'Test::More'               => '0',
        'Test2::Bundle::Numerical' => '0.03',
    },
    PREREQ_PM => {},
    PM    => {
        'lib/Font/Metrics.pm'               => '$(INST_LIB)/Font/Metrics.pm',
        'lib/Font/Metrics/Install/Files.pm' => '$(INST_LIB)/Font/Metrics/Install/Files.pm',
        'include/fm.h'                      => '$(INST_LIB)/Font/Metrics/include/fm.h',
        'fm_metrics.c'                      => '$(INST_LIB)/Font/Metrics/src/fm_metrics.c',
        'fm_std14.c'                        => '$(INST_LIB)/Font/Metrics/src/fm_std14.c',
        'fm_truetype.c'                     => '$(INST_LIB)/Font/Metrics/src/fm_truetype.c',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Font-Metrics-* Metrics.c Metrics.o Metrics.bs *.o lib/Font/Metrics/Install/Files.pm' },
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
