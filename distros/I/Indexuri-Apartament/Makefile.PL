use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Indexuri::Apartament',
    AUTHOR           => q{Mihai Cornel <mhcrnl@gmail.com>},
    VERSION_FROM     => 'lib/Indexuri/Apartament.pm',
    ABSTRACT_FROM    => 'lib/Indexuri/Apartament.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'              => 1.36,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Indexuri-Apartament-*' },
);
