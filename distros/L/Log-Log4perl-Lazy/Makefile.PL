use 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Log::Log4perl::Lazy',
    AUTHOR           => q{Mahiro Ando <mahiro@cpan.org>},
    VERSION_FROM     => 'lib/Log/Log4perl/Lazy.pm',
    ABSTRACT_FROM    => 'lib/Log/Log4perl/Lazy.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'    => 0,
        'Test::Output'  => 0,
    },
    PREREQ_PM => {
        'Log::Log4perl' => 1.42,
        'Params::Lazy'  => 0.005,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Log-Log4perl-Lazy-*' },
);
