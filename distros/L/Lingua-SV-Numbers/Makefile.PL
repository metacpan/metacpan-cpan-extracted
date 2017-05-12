use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::SV::Numbers',
    AUTHOR              => q{Tim Nordenfur <tim@gurka.se>},
    VERSION_FROM        => 'lib/Lingua/SV/Numbers.pm',
    ABSTRACT_FROM       => 'lib/Lingua/SV/Numbers.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-SV-Numbers-*' },
);
