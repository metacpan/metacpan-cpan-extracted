use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'FSM::Basic',
    AUTHOR           => q{DULAUNOY Fabrice <fabrice@dulaunoy.com>},
    VERSION_FROM     => 'lib/FSM/Basic.pm',
    ABSTRACT_FROM    => 'lib/FSM/Basic.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'autovivification'              => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'FSM-Basic-*' },
);
