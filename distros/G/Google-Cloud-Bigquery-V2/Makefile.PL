use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Google::Cloud::Bigquery::V2',
    AUTHOR           => ['C.J. Collier <cjac@google.com>'],
    VERSION_FROM     => 'lib/Google/Cloud/Bigquery/V2.pm',
    ABSTRACT_FROM    => 'lib/Google/Cloud/Bigquery/V2.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Moo'                     => '0',
        'Net::Curl'               => '0',
        'Log::Any'                => '0',
        'Google::Auth'            => '0.01',
        'Google::gRPC::Client'    => '0.01',
        'Google::Api::Common'     => '0.01',
        'Protobuf'                => '0.01',

        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Google-Cloud-Bigquery-V2-*' },
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
