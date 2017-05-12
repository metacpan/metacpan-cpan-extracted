use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Marathon',
    AUTHOR           => q{Sebastian Geidies <seb@geidi.es>},
    VERSION_FROM     => 'lib/Marathon.pm',
    ABSTRACT_FROM    => 'lib/Marathon.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'LWP::UserAgent' => 6.13,
        'JSON::XS'       => 3.01,
        'AnyEvent'       => 7.11,
        'IO::All'        => 0.86,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Marathon-*' },
);
