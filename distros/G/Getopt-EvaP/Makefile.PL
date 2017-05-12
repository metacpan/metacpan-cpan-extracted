
use ExtUtils::MakeMaker;

use Config;

WriteMakefile(
    'NAME'         => 'Getopt::EvaP',
    'EXE_FILES'    => ['genpTk'],
    'PMLIBDIRS'    => ['Evap'],
    'VERSION_FROM' => 'EvaP.pm',
    ($] >= 5.005 ?
       (ABSTRACT   => 'Long/short options, multilevel help, types, defaults, embeddable, pTk GUI',
        AUTHOR     => 'Steve Lidie (Stephen.O.Lidie@Lehigh.EDU)') : ()),
    'dist'         => {COMPRESS => 'gzip', SUFFIX => 'gz'}
);
