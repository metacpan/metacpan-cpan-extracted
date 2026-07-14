use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Google::Cloud::Compute::V1',
    AUTHOR           => ['C.J. Collier <cjac@google.com>'],
    VERSION_FROM     => 'lib/Google/Cloud/Compute/V1.pm',
    ABSTRACT         => 'Google Cloud Compute Engine V1 API Client',
    LICENSE          => 'apache_2_0',
    MIN_PERL_VERSION => '5.008003',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Moo'                  => '0',
        'Log::Any'             => '0',
        'Google::Auth'         => '0.02',
        'Google::gRPC::Client' => '0.02',
        'Google::Api::Common'  => '0.01',
        'Protobuf'             => '0.05',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Google-Cloud-Compute-V1-*' },
);
