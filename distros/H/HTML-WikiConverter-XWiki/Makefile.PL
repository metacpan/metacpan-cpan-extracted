use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::WikiConverter::XWiki',
    AUTHOR              => 'Patrick Staehlin <packi@cpan.org>',
    VERSION_FROM        => 'lib/HTML/WikiConverter/XWiki.pm',
    ABSTRACT_FROM       => 'lib/HTML/WikiConverter/XWiki.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'URI' => 1.35,
        'HTML::WikiConverter' => 0.62,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-WikiConverter-XWiki-*' },
);
