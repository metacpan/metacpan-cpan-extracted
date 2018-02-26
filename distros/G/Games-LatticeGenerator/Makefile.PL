use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Games::LatticeGenerator',
    AUTHOR           => q{Pawel Biernacki <pawel.f.biernacki@gmail.com>},
    VERSION_FROM     => 'lib/Games/LatticeGenerator.pm',
    ABSTRACT_FROM    => 'lib/Games/LatticeGenerator.pm',
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
        'Math::Trig'		=> 1.23,
        'GD::Simple'		=> undef,
        'GD::Image'			=> 2.38,
        'AI::Prolog'		=> 0.741,
        'Capture::Tiny'		=> 0.25,
        'Carp'				=> 1.36
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Games-LatticeGenerator-*' },
);
