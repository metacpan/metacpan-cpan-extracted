use 5.016;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Base::Wrapper ();
use Config;

# https://docs.wasmtime.dev/stability-platform-support.html#platform-support
$^O =~ /^(linux|darwin|windows)$/ or die 'OS unsupported';
if ($^O eq 'linux') {
    $Config{archname} =~ /(x86_64|aarch64|s390x|riscv64)/ or die 'OS unsupported';
}

my %WriteMakefileArgs = Alien::Base::Wrapper->new('Alien::libextism')->mm_args2(
    NAME             => 'Extism',
    AUTHOR           => q{Extism Authors <extism@cpan.org>},
    VERSION_FROM     => 'lib/Extism.pm',
    ABSTRACT_FROM    => 'lib/Extism.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.016',
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {},
    XSMULTI        => 1,
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Extism-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/extism/perl-sdk.git',
                web  => 'https://github.com/extism/perl-sdk',
            },
            bugtracker => {
                web => 'https://github.com/extism/perl-sdk/issues'
            },
            homepage   => 'https://github.com/extism/perl-sdk',
        },
        prereqs => {
            configure => {
                requires => {
                    "Alien::libextism" => "v0.1.1",
                }
            }
        },
    },
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
