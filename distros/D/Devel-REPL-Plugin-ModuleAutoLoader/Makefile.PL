use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Devel::REPL::Plugin::ModuleAutoLoader',
    AUTHOR           => q{James Ronan <james@ronanweb.co.uk>},
    VERSION_FROM     => 'lib/Devel/REPL/Plugin/ModuleAutoLoader.pm',
    ABSTRACT_FROM    => 'lib/Devel/REPL/Plugin/ModuleAutoLoader.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Devel::REPL::Plugin' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Devel-REPL-Plugin-ModuleAutoLoader-*' },
);
