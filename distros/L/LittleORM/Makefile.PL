use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'LittleORM',
    AUTHOR           => q{Eugene Kuzin <eugenek@45-98.org>},
    VERSION_FROM     => 'lib/LittleORM.pm',
    ABSTRACT_FROM    => 'lib/LittleORM.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moose'                        => 0,
	'Carp::Assert'                 => 0,
	'List::MoreUtils'              => 0,
	'Scalar::Util'                 => 0,
	'Moose::Util::TypeConstraints' => 0

    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'LittleORM-*' },
);
