use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Debug::Simple',
    AUTHOR              => 'Behan Webster <behanw@websterwood.com>',
    VERSION_FROM        => 'lib/Debug/Simple.pm',
    ABSTRACT_FROM       => 'lib/Debug/Simple.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Debug-Simple-*' },
);
