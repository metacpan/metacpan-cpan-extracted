use 5.006;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::Ratings',
    AUTHOR              => 'Christian Bartolomaeus <bartolin@gmx.de>',
    VERSION_FROM        => 'lib/Games/Ratings.pm',
    ABSTRACT_FROM       => 'lib/Games/Ratings.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
        'Class::Std::Utils' => 0,
        'version'           => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-Ratings-*' },
);
