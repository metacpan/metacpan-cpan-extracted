use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'IO::Busy',
    AUTHOR              => 'Damian Conway <DCONWAY@cpan.org>',
    VERSION_FROM        => 'lib/IO/Busy.pm',
    ABSTRACT_FROM       => 'lib/IO/Busy.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Perl6::Export::Attrs' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IO-Busy-*' },
);
