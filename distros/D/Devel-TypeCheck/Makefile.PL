use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Devel::TypeCheck',
    AUTHOR              => 'Gary Jackson <bargle@umiacs.umd.edu>',
    VERSION_FROM        => 'lib/Devel/TypeCheck.pm',
    ABSTRACT_FROM       => 'lib/Devel/TypeCheck.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Devel-TypeCheck-*' },
);
