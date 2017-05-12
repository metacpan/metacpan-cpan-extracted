use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'LJ::Schedule',
    AUTHOR              => 'Ben Evans <ben@bpfh.net>',
    VERSION_FROM        => 'lib/LJ/Schedule.pm',
    ABSTRACT_FROM       => 'lib/LJ/Schedule.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'LJ-Schedule-*' },
);
