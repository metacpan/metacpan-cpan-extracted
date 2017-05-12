use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'IO::Prompt',
    AUTHOR              => 'Damian Conway <DCONWAY@cpan.org>',
    VERSION_FROM        => 'lib/IO/Prompt.pm',
    ABSTRACT_FROM       => 'lib/IO/Prompt.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'IO::Handle'    => 0,
        'Term::ReadKey' => 0,
        'Want'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IO-Prompt-*' },
);
