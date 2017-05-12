
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Filesys::MakeISO',
    AUTHOR          => 'Uwe Voelker <uwe.voelker@gmx.de>',
    VERSION_FROM    => 'lib/Filesys/MakeISO.pm',
    ABSTRACT_FROM   => 'lib/Filesys/MakeISO.pm',
    PL_FILES        => {},
    PREREQ_PM       => {'Module::Pluggable' => 0,
                        'Test::More'        => 0,
                        'version'           => 0,
                       },
    dist            => {COMPRESS => 'gzip -9f',
                        SUFFIX   => 'gz',
                       },
    clean           => {FILES    => 'lib/Filesys/MakeISO.pm-*'},
);
