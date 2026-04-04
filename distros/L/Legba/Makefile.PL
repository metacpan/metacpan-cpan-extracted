use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Legba',
    VERSION_FROM     => 'lib/Legba.pm',
    ABSTRACT         => 'Ultra-fast global slot storage implemented in XS',
    AUTHOR           => 'LNATION <email@lnation.org>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010001',
    PREREQ_PM        => {},
    TEST_REQUIRES    => {
        'Test::More' => '0.88',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    clean => { FILES => '*.o *.c *.bs' },
);
