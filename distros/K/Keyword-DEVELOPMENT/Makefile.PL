use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Keyword::DEVELOPMENT',
    AUTHOR        => q{Curtis "Ovid" Poe <ovid@allaroundtheworld.fr>},
    VERSION_FROM  => 'lib/Keyword/DEVELOPMENT.pm',
    ABSTRACT_FROM => 'lib/Keyword/DEVELOPMENT.pm',
    LICENSE       => 'artistic_2',
    PL_FILES      => {},
    MIN_PERL_VERSION   => '5.012',    # for pluggable keywords
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Keyword::Simple' => '0.04',
    },
    dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => 'Keyword-DEVELOPMENT-*' },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:Ovid/keyword-development.github',
                web  => 'https://github.com/Ovid/keyword-development',
            },
        },
    },
);
