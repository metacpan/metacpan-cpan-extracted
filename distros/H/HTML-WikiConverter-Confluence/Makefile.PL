use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::WikiConverter::Confluence',
    AUTHOR              => 'David J. Iberri <diberri@cpan.org>',
    VERSION_FROM        => 'lib/HTML/WikiConverter/Confluence.pm',
    ABSTRACT_FROM       => 'lib/HTML/WikiConverter/Confluence.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-WikiConverter-Confluence-*' },
);
