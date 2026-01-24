use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Get XS::JIT build flags portably
my ($xs_jit_cflags, $xs_jit_libs);
eval {
    require XS::JIT;
    $xs_jit_cflags = XS::JIT->cflags();
    $xs_jit_libs   = XS::JIT->libs();
};
if ($@) {
    die "XS::JIT is required but could not be loaded: $@\n"
      . "Please install XS::JIT first: cpanm XS::JIT\n";
}

my %WriteMakefileArgs = (
    NAME             => 'Meow',
    AUTHOR           => q{LNATION <email@lnation.org>},
    VERSION_FROM     => 'lib/Meow.pm',
    ABSTRACT_FROM    => 'lib/Meow.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    XSMULTI          => 1,
    INC              => $xs_jit_cflags,
    LIBS             => [$xs_jit_libs],
    macro            => { TARFLAGS => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'XS::JIT'             => '0.03',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Basic::Types::XS' => 0.05,
        'XS::JIT'          => '0.02',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Meow-*' },
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
