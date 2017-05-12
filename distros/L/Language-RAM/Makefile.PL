use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Language::RAM',
    AUTHOR           => q{Fabian Stiewitz <deprint@cpan.org>},
    VERSION_FROM     => 'lib/Language/RAM.pm',
    ABSTRACT_FROM    => 'lib/Language/RAM.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    EXE_FILES => [
        'script/ram.pl'
    ],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Language-RAM-*' },
);
