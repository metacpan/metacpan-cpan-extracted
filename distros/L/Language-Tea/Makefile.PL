use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Language::Tea',
    AUTHOR              => 'Mario Silva <mario.silva@verticalone.pt>',
    VERSION_FROM        => 'lib/Language/Tea.pm',
    ABSTRACT_FROM       => 'lib/Language/Tea.pm',
    EXE_FILES            => [ 'bin/destea' ],
    PREREQ_PM => {
        'Test::More' => 0,
        'Scalar::Util' => 0,
        'v6' => 0,
        'Symbol' => 0,
        'IPC::Open2' => 0,
        'IPC::Open2' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Language-Tea-*' },
);
