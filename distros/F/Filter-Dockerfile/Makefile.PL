use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Filter::Dockerfile',
    AUTHOR           => q{Cory Bennett <cpan@corybennett.org>},
    VERSION_FROM     => 'lib/Filter/Dockerfile.pm',
    ABSTRACT_FROM    => 'lib/Filter/Dockerfile.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    EXE_FILES => ['bin/dfpp'],
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Filter::Util::Call' => 0,
        'LWP::UserAgent' => 0,
        'Mozilla::CA' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Filter-Dockerfile-*' },
);
