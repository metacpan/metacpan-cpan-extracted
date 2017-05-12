use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::Score',
    AUTHOR              => 'Jose Castro <cog@cpan.org>',
    VERSION_FROM        => 'lib/Games/Score.pm',
    ABSTRACT_FROM       => 'lib/Games/Score.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-Score-*' },
);
