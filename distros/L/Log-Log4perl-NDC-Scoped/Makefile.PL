use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Log::Log4perl::NDC::Scoped',
    AUTHOR           => q{Rafael Porres Molina <rporres@gmail.com>},
    VERSION_FROM     => 'lib/Log/Log4perl/NDC/Scoped.pm',
    ABSTRACT_FROM    => 'lib/Log/Log4perl/NDC/Scoped.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'File::Temp' => 0,
    },
    PREREQ_PM => {
        'Log::Log4perl' => 0,
        'Carp'          => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Log-Log4perl-NDC-Scoped-*' },
);
