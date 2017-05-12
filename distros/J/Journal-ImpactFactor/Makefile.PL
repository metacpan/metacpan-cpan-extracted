use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Journal::ImpactFactor',
    AUTHOR           => q{Felipe da Veiga Leprevost <leprevost@cpan.org>},
    VERSION_FROM     => 'lib/Journal/ImpactFactor.pm',
    ABSTRACT_FROM    => 'README.pod',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Moose' => 0,
        'namespace::autoclean' => 0,
        'Storable' => 0,
    },

    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
    	    resources => {
                homepage   => 'https://github.com/Leprevost/Journal-ImpactFactor',
                repository => 'https://github.com/Leprevost/Journal-ImpactFactor.git',
                bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Journal-ImpactFactor',
            },
        })
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Journal-ImpactFactor-*' },
);
