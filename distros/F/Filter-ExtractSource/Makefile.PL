use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Filter::ExtractSource',
    AUTHOR              => 'Jon Allen <jj@jonallen.info>',
    VERSION_FROM        => 'lib/Filter/ExtractSource.pm',
    ABSTRACT_FROM       => 'lib/Filter/ExtractSource.pm',
    PREREQ_PM => {
        'Test::More'     => 0,
        'Filter::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Filter-ExtractSource-*' },
);
