use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::ContentExtractor',
    AUTHOR              => 'Zhang Jun <jzhang533@gmail.com>',
    VERSION_FROM        => 'lib/HTML/ContentExtractor.pm',
    ABSTRACT_FROM       => 'lib/HTML/ContentExtractor.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.64,
        'HTML::TreeBuilder' => 3.13,
        'HTML::TableExtract' => 2.10
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-ContentExtractor-*' },
);
