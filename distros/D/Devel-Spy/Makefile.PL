#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Devel::Spy',
    AUTHOR        => 'Joshua ben Jore <jjore@cpan.org>',
    VERSION_FROM  => 'lib/Devel/Spy.pm',
    ABSTRACT_FROM => 'lib/Devel/Spy.pm',
    PM => {
        'lib/Devel/Spy.pm' => '$(INST_LIB)/Devel/Spy.pm',
        'lib/Devel/Spy/_obj.pm' => '$(INST_LIB)/Devel/Spy/_obj.pm',
        'lib/Devel/Spy/_overload.pm' => '$(INST_LIB)/Devel/Spy/_overload.pm',
        'lib/Devel/Spy/_constants.pm' => '$(INST_LIB)/Devel/Spy/_constants.pm',
        'lib/Devel/Spy/Util.pm' => '$(INST_LIB)/Devel/Spy/Util.pm',
        'lib/Devel/Spy/TieScalar.pm' => '$(INST_LIB)/Devel/Spy/TieScalar.pm',
        'lib/Devel/Spy/TieArray.pm' => '$(INST_LIB)/Devel/Spy/TieArray.pm',
        'lib/Devel/Spy/TieHash.pm' => '$(INST_LIB)/Devel/Spy/TieHash.pm',
        'lib/Devel/Spy/TieHandle.pm' => '$(INST_LIB)/Devel/Spy/TieHandle.pm',
    },
    PL_FILES      => {
        'overload.PL' => 'lib/Devel/Spy/_overload.pm'
    },
    PREREQ_PM     => {
        'strict'         => 0,
        'warnings'       => 0,
        'overload'       => 0,
        'constant'       => 0,
        'Test::More'     => 0,

        'Test::Class'    => 0,
        'Test::Warn'     => 0,
        'UNIVERSAL::ref' => 0,
        'Sub::Name'      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Devel-Spy-* lib/Devel/Spy/_overload.pm' },
);
