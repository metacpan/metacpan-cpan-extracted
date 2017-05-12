use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::WikiConverter::Kwiki',
    AUTHOR              => 'David J. Iberri <diberri@cpan.org>',
    VERSION_FROM        => 'lib/HTML/WikiConverter/Kwiki.pm',
    ABSTRACT_FROM       => 'lib/HTML/WikiConverter/Kwiki.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'HTML::WikiConverter' => 0.55,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-WikiConverter-Kwiki-*' },
);
