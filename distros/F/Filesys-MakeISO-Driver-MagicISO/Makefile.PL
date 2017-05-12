
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Filesys::MakeISO::Driver::MagicISO',
    AUTHOR          => 'Uwe Voelker <uwe.voelker@gmx.de>',
    VERSION_FROM    => 'lib/Filesys/MakeISO/Driver/MagicISO.pm',
    ABSTRACT_FROM   => 'lib/Filesys/MakeISO/Driver/MagicISO.pm',
    PL_FILES        => {},
    PREREQ_PM       => {'File::Which'      => 0,
                        'Filesys::MakeISO' => '0.1.0',
                        'IPC::Run3'        => 0,
                        'Test::More'       => 0,
                        'version'          => 0,
                       },
    dist            => {COMPRESS => 'gzip -9f',
                        SUFFIX   => 'gz',
                       },
    clean           => {FILES => 'lib/Filesys/MakeISO/Driver/MagicISO.pm-*'},
);
