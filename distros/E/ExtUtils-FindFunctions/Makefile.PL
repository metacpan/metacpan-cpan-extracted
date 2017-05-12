use strict;
use ExtUtils::MakeMaker;
eval "use ExtUtils::MakeMaker";

WriteMakefile(
    NAME                => 'ExtUtils::FindFunctions',
    LICENSE             => 'perl',
    AUTHOR              => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/ExtUtils/FindFunctions.pm',
    ABSTRACT_FROM       => 'lib/ExtUtils/FindFunctions.pm',
    EXE_FILES           => [ 'bin/install-extutils-findfunctions' ], 
    PREREQ_PM => {
        'Test::More' => 0,
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ExtUtils-FindFunctions-*' },
);
