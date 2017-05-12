use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Finance::BlockIO',
    AUTHOR           => q{Ryan Northrup <northrup@cpan.org>},
    VERSION_FROM     => 'lib/Finance/BlockIO.pm',
    ABSTRACT_FROM    => 'lib/Finance/BlockIO.pm',
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
        'WWW::Curl::Simple'     => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Finance-BlockIO-*' },
);
