use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::WikiConverter::WikkaWiki',
    AUTHOR              => 'David J. Iberri <diberri@cpan.org>',
    VERSION_FROM        => 'lib/HTML/WikiConverter/WikkaWiki.pm',
    ABSTRACT_FROM       => 'lib/HTML/WikiConverter/WikkaWiki.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'URI' => 1.35,
        'HTML::WikiConverter' => 0.50,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-WikiConverter-WikkaWiki-*' },
);
