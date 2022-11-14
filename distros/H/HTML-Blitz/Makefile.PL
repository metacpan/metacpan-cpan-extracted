use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT_FROM      => 'lib/HTML/Blitz.pm',
    AUTHOR             => ['Lukas Mai <l.mai@web.de>'],
    CONFIGURE_REQUIRES => {
        strict                => 0,
        warnings              => 0,
        'ExtUtils::MakeMaker' => '6.76',
    },
    LICENSE            => 'agpl_3',
    MIN_PERL_VERSION   => v5.20.0,
    NAME               => 'HTML::Blitz',
    PREREQ_PM          => {
        constant               => 0,
        feature                => 0,
        indirect               => '0.36',
        overload               => 0,
        strict                 => 0,
        warnings               => 0,
        'Carp'                 => 0,
        'Exporter'             => '5.57',
        'Function::Parameters' => '2',
        'List::Util'           => '1.33',
        'Scalar::Util'         => 0,
    },
    TEST_REQUIRES      => {
        'Fcntl'         => 0,
        'File::Temp'    => '0.2307',
        'FindBin'       => 0,
        'Test::Builder' => 0,
        'Test::Fatal'   => 0,
        'Test::More'    => '0.88',
    },
    VERSION_FROM       => 'lib/HTML/Blitz.pm',
    test               => { RECURSIVE_TEST_FILES => 1 },
);
