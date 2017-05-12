use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::Template::Filter::TT2',
    LICENSE             => 'perl',
    AUTHOR              => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/HTML/Template/Filter/TT2.pm',
    ABSTRACT_FROM       => 'lib/HTML/Template/Filter/TT2.pm',
    PREREQ_PM => {
        'HTML::Template' => 0,
        'Test::More'     => 0,
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-Template-Filter-TT2-*' },
);
