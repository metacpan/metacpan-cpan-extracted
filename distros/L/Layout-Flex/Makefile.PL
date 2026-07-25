use 5.008003;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Path qw(make_path);

make_path('lib/Font/Metrics/Install');

my $dep  = ExtUtils::Depends->new('Layout::Flex', 'Font::Metrics');
my %deps = $dep->get_makefile_vars;

# Find Font::Metrics' static archive so Linux's ld can resolve fm_* symbols
# at link time (macOS uses -undefined dynamic_lookup; Linux does not).
my $fm_lib;
for my $inc (@INC) {
    my $p = "$inc/auto/Font/Metrics/libfm$Config{_a}";
    if (-f $p) { $fm_lib = $p; last; }
}
die "Cannot find Font::Metrics static library (libfm$Config{_a})\n"
  . "Install Font::Metrics >= 0.03 first.\n" unless $fm_lib;

my %WriteMakefileArgs = (
    NAME             => 'Layout::Flex',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Layout/Flex.pm',
    ABSTRACT_FROM    => 'lib/Layout/Flex.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    INC              => join(' ', '-I. -Iinclude', $deps{INC} // ()),
    LDFROM           => "Flex\$(OBJ_EXT) $fm_lib",
    XS               => { 'Flex.xs' => 'Flex.c' },
    macro            => { TARFLAGS => '--format=ustar -c -v -f' },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0',
        'Font::Metrics' => '0.03',
    },
    PREREQ_PM => {
        'Font::Metrics' => '0.03',
    },
    TEST_REQUIRES => {
        'Test::More'               => '0',
        'Test2::Bundle::Numerical' => '0.03',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Layout-Flex-* Flex.c Flex.bs' },
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
