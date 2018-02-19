use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Devel::Scope',
    AUTHOR           => q{Felix Tubiana <felixtubiana@gmail.com>},
    VERSION_FROM     => 'lib/Devel/Scope.pm',
    ABSTRACT_FROM    => 'lib/Devel/Scope.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Term::Colormap'     => '0.18',
        'Scope::Upper'       => '0.30',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Devel-Scope-*' },
);
