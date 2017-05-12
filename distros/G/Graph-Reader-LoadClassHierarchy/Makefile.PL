use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Graph::Reader::LoadClassHierarchy',
    AUTHOR              => 'Florian Ragwitz <rafl@debian.org>',
    VERSION_FROM        => 'lib/Graph/Reader/LoadClassHierarchy.pm',
    ABSTRACT_FROM       => 'lib/Graph/Reader/LoadClassHierarchy.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Graph'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Graph-Reader-LoadClassHierarchy-*' },
);
