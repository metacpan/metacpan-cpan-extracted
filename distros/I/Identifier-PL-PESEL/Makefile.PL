use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Identifier::PL::PESEL',
    AUTHOR           => q{Andrzej Cholewiusz <cholewiusz@gmail.com>},
    VERSION_FROM     => 'lib/Identifier/PL/PESEL.pm',
    ABSTRACT_FROM    => 'lib/Identifier/PL/PESEL.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	'Test::More' => 0,
	'Test::Exception' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Identifier-PL-PESEL-*' },
);
