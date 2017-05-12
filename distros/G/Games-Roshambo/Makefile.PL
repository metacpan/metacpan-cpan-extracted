use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::Roshambo',
    AUTHOR              => 'Chris Thompson <cpan@cthompson.com>',
    VERSION_FROM        => 'lib/Games/Roshambo.pm',
    ABSTRACT_FROM       => 'lib/Games/Roshambo.pm',
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-Roshambo-*' },
);
