use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lyrics::Fetcher::LyrDB',
    AUTHOR              => 'Joshua Soles <jbsoles@gmail.com>',
    VERSION_FROM        => 'lib/Lyrics/Fetcher/LyrDB.pm',
    ABSTRACT_FROM       => 'lib/Lyrics/Fetcher/LyrDB.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lyrics-Fetcher-LyrDB-*' },
);
