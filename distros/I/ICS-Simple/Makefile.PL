use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ICS::Simple',
    AUTHOR              => 'Dusty Wilson <cpan-ics-simple@dusty.hey.nu>',
    VERSION_FROM        => 'lib/ICS/Simple.pm',
    ABSTRACT_FROM       => 'lib/ICS/Simple.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'ICS' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ICS-Simple-*' },
);
