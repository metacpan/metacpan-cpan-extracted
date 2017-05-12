use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::Cards::Bridge::Contract',
    AUTHOR              => 'David Westbrook <dwestbrook@gmail.com>',
    VERSION_FROM        => 'lib/Games/Cards/Bridge/Contract.pm',
    ABSTRACT_FROM       => 'lib/Games/Cards/Bridge/Contract.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-Cards-Bridge-Contract-*' },
);
