use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Lingua::StopWords',
    AUTHOR        => 'Marvin Humphrey <marvin at rectangular dot com>',
    VERSION_FROM  => 'lib/Lingua/StopWords.pm',
    ABSTRACT_FROM => 'lib/Lingua/StopWords.pm',
    PREREQ_PM     => {},
    clean         => { FILES => 'Lingua-StopWords-* MANIFEST.bak' },
);
