use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Hex::Record',
    AUTHOR           => q{spebern <bernhard@specht.net>},
    VERSION_FROM     => 'lib/Hex/Record.pm',
    ABSTRACT_FROM    => 'lib/Hex/Record.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'     => 0,
    },
    PREREQ_PM => {
        'Test::Warn'      => 0,
        'Clone'           => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Hex-Record-*' },
);
