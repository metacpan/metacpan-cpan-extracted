use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Finance::Nadex',
    AUTHOR           => q{mhandisi <mhandisi@cpan.org>},
    VERSION_FROM     => 'lib/Finance/Nadex.pm',
    ABSTRACT_FROM    => 'lib/Finance/Nadex.pm',
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
        'JSON'                 => 0,
        'LWP::Protocol::https' => 0,
        'LWP::UserAgent'       => 0,
        'Test::LWP::UserAgent' => 0,
        'Test::Exception'      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Nadex-API-*' },
);
