use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'LendingClub::API',
    AUTHOR           => q{Michael Renz <cryptographrix+cpan@gmail.com>},
    VERSION_FROM     => 'lib/LendingClub/API.pm',
    ABSTRACT_FROM    => 'lib/LendingClub/API.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'JSON' => 0,
        'Hash::Flatten' => 0,
        'LWP::UserAgent' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'LendingClub-API-*' },
);
