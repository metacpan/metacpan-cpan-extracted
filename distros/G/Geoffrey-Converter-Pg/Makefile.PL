use 5.016;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Geoffrey::Converter::Pg',
    AUTHOR             => q{Mario Zieschang <mziescha@cpan.org>},
    VERSION_FROM       => 'lib/Geoffrey/Converter/Pg.pm',
    ABSTRACT_FROM      => 'lib/Geoffrey/Converter/Pg.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.016,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Geoffrey'        => 0.000103,
        'Readonly'        => 0,
        'Test::Exception' => 0,
    },
    TEST_REQUIRES => {
        'Test::PostgreSQL' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Geoffrey-Converter-Pg-*' },
);
