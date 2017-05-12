use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::DisableForm',
    AUTHOR              => 'Naoya Ito <naoya@bloghackers.net>',
    VERSION_FROM        => 'lib/HTML/DisableForm.pm',
    ABSTRACT_FROM       => 'lib/HTML/DisableForm.pm',
    PREREQ_PM => {
        'Test::More'   => 0,
        warnings     => 0,
        'HTML::Parser' => 3.26,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-DisableForm-*' },
);
