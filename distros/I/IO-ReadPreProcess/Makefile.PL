# Perl makefile for IO::ReadPreProcess
#       SCCS: @(#)Makefile.PL	1.2 05/22/17 18:34:21

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'IO::ReadPreProcess',
    AUTHOR           => q{Alain Williams <addw@phcomp.co.uk>},
    VERSION_FROM     => 'lib/IO/ReadPreProcess.pm',
    ABSTRACT_FROM    => 'lib/IO/ReadPreProcess.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	'Math::Expression'	=> '1.47',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'IO-ReadPreProcess-*' },
);
