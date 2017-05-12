use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'LoadHtml',
    AUTHOR              => 'Jim Turner <turnerjw@wwol.com>',
    VERSION_FROM        => 'lib/LoadHtml.pm',
    ABSTRACT_FROM       => 'lib/LoadHtml.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'LoadHtml-*' },
);
