use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::WikiConverter::Wikispaces',
    AUTHOR              => 'Martin Budden <mjbudden@gmail.com>',
    VERSION_FROM        => 'lib/HTML/WikiConverter/Wikispaces.pm',
    ABSTRACT_FROM       => 'lib/HTML/WikiConverter/Wikispaces.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'HTML::WikiConverter' => 0.52,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-WikiConverter-Wikispaces-*' },
);
