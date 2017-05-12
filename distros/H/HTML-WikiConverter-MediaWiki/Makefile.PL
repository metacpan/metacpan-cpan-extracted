use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::WikiConverter::MediaWiki',
    AUTHOR              => 'David J. Iberri <diberri@cpan.org>',
    VERSION_FROM        => 'lib/HTML/WikiConverter/MediaWiki.pm',
    ABSTRACT_FROM       => 'lib/HTML/WikiConverter/MediaWiki.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'URI' => 1.35,
        'HTML::WikiConverter' => 0.63, # for the 'table w/ blocks' test
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-WikiConverter-MediaWiki-*' },
);
