use strict;
use ExtUtils::MakeMaker;

&WriteMakefile(
    NAME          => 'MARC::Lint',
    DISTNAME      => 'MARC-Lint',
    VERSION_FROM  => 'lib/MARC/Lint.pm',
    ABSTRACT_FROM => 'lib/MARC/Lint.pm',
    AUTHOR        => 'Bryan Baldus <eijabb@cpan.org>',
    PREREQ_PM     => {
                        'Test::More' => 0,
                        'MARC::Record' => 0,
                        'Business::ISBN' => 0,
                     },
    EXE_FILES     => [ qw( bin/marclint ) ],
);
