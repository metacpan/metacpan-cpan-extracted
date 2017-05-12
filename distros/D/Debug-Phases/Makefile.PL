use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Debug::Phases',
    AUTHOR              => 'Damian Conway <DCONWAY@cpan.org>',
    VERSION_FROM        => 'lib/Debug/Phases.pm',
    ABSTRACT_FROM       => 'lib/Debug/Phases.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Time::HiRes'=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Debug-Phases-*' },
);
