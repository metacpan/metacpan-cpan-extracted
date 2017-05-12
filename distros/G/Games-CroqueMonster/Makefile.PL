use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::CroqueMonster',
    AUTHOR              => 'Arnaud Dupuis <a.dupuis@infinityperl.org>',
    VERSION_FROM        => 'lib/Games/CroqueMonster.pm',
    ABSTRACT_FROM       => 'lib/Games/CroqueMonster.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'XML::Simple' => '2.18',
        'LWP::Simple' => '1.41',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-CroqueMonster-*' },
);
