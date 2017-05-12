use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hatena::Keyword::Similar',
    AUTHOR              => 'Naoya Ito <naoya@bloghackers.net>',
    VERSION_FROM        => 'lib/Hatena/Keyword/Similar.pm',
    ABSTRACT_FROM       => 'lib/Hatena/Keyword/Similar.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Hatena::Keyword' => 0.04,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hatena-Keyword-Similar-*' },
);
