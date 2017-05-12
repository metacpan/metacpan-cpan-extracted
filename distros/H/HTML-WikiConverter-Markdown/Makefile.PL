use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::WikiConverter::Markdown',
    AUTHOR              => 'David J. Iberri <diberri@cpan.org>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/HTML/WikiConverter/Markdown.pm',
    ABSTRACT_FROM       => 'lib/HTML/WikiConverter/Markdown.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'HTML::WikiConverter' => 0.67, # for p_strict attribute
        'HTML::Tagset' => 0,
        'Params::Validate' => 0,
        'URI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-WikiConverter-Markdown-*' },
);
