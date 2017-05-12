use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::Jumble',
    AUTHOR              => 'Doug Sparling <usr_bin_perl@yahoo.com>',
    VERSION_FROM        => 'lib/Games/Jumble.pm',
    ABSTRACT_FROM       => 'lib/Games/Jumble.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-Jumble-*' },
);
