use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::WikiConverter::PbWiki',
    AUTHOR              => 'Dave Schaefer <dschaefer@cpan.org>',
    VERSION_FROM        => 'lib/HTML/WikiConverter/PbWiki.pm',
    ABSTRACT_FROM       => 'lib/HTML/WikiConverter/PbWiki.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'HTML::WikiConverter' => 0.51,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-WikiConverter-PbWiki-*' },
);
