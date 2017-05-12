use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Getopt::Whatever',
    AUTHOR              => 'Josh McAdams <joshua.mcadams@gmail.com>',
    VERSION_FROM        => 'lib/Getopt/Whatever.pm',
    ABSTRACT_FROM       => 'lib/Getopt/Whatever.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    LICENSE             => 'perl',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Getopt-Whatever-*' },
);
