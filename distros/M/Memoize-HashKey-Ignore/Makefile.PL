use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Memoize::HashKey::Ignore',
    AUTHOR           => q{binary.com <rakesh@binary.com>},
    VERSION_FROM     => 'lib/Memoize/HashKey/Ignore.pm',
    ABSTRACT_FROM    => 'lib/Memoize/HashKey/Ignore.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'         => 0,
        'Test::NoWarnings'   => 0,
        'Test::FailWarnings' => 0,
        'Test::Exception'    => 0,
    },
    PREREQ_PM => {
        'Memoize'   => 0,
        'Try::Tiny' => 0,
    },
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
            resources => {
                homepage   => 'https://github.com/binary-com/perl-Memoize-HashKey-Ignore',
                repository => 'git@github.com:binary-com/perl-Memoize-HashKey-Ignore.git',
                bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Memoize-HashKey-Ignore',
            },
        })
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Memoize-HashKey-Ignore-*' },
);
