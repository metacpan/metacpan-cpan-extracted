use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::WikiConverter::Socialtext',
    AUTHOR              => 'Kirsten L. Jones <kirsten@gmail.com>',
    VERSION_FROM        => 'lib/HTML/WikiConverter/Socialtext.pm',
    ABSTRACT_FROM       => 'lib/HTML/WikiConverter/Socialtext.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'URI' => 1.35,
        'HTML::WikiConverter' => 0.54,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-WikiConverter-Socialtext-*' },
);
