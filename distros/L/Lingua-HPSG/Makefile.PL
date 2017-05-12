use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::HPSG',
    AUTHOR              => 'C.J. Adams-Collier <cjac@u.washington.edu>',
    VERSION_FROM        => 'lib/Lingua/HPSG.pm',
    ABSTRACT_FROM       => 'lib/Lingua/HPSG.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-HPSG-*' },
);
