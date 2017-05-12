use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Geo::IATA',
    AUTHOR              => 'Joerg Meltzer <joerg <at> joergmeltzer.de>',
    VERSION_FROM        => 'lib/Geo/IATA.pm',
    ABSTRACT_FROM       => 'lib/Geo/IATA.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'  => 0,
        'version'     => 0,
        'DBD::SQLite' => 0,
        'DBI'         => 0,
        'version'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Geo-IATA-*' },
);
