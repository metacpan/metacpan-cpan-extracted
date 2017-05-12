use strict;
use ExtUtils::MakeMaker;

&WriteMakefile(
    NAME          => 'MARC::File::MARCMaker',
    DISTNAME      => 'MARC-File-MARCMaker',
    VERSION_FROM  => 'lib/MARC/File/MARCMaker.pm',
    AUTHOR        => 'Bryan Baldus <eijabb@cpan.org>',
    PREREQ_PM     => {
                        'Test::More' => 0,
                        'MARC::Record' => 0,
                     },
    EXE_FILES     => [ qw( bin/mkr2mrc bin/mrc2mkr ) ],
);
