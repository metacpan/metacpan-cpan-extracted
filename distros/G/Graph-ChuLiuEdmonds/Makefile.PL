use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Graph::ChuLiuEdmonds',
    AUTHOR              => 'Petr Pajas <pajas@matfyz.cz>',
    VERSION_FROM        => 'lib/Graph/ChuLiuEdmonds.pm',
    ABSTRACT_FROM       => 'lib/Graph/ChuLiuEdmonds.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Graph' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Graph-ChuLiuEdmonds-*' },
);
