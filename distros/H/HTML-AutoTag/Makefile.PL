use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'HTML::AutoTag',
    AUTHOR           => q{Jeff Anderson <jeffa@cpan.org>},
    VERSION_FROM     => 'lib/HTML/AutoTag.pm',
    ABSTRACT_FROM    => 'lib/HTML/AutoTag.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'HTML::Entities'        => 3.69,
        'Tie::Hash::Attribute'  => 1.04,
    },
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
            resources => {
                homepage   => 'https://github.com/jeffa/HTML-AutoTag',
                repository => 'https://github.com/jeffa/HTML-AutoTag.git',
            },
        })
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'HTML-AutoTag-*' },
);
