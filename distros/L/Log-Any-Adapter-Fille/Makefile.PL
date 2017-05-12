use 5.008001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Log::Any::Adapter::Fille',
    AUTHOR           => [ 'Mikhail Ivanov <m.ivanych@gmail.com>', 'Anastasia Zherebtsova <zherebtsova@gmail.com>' ],
    VERSION_FROM     => 'lib/Log/Any/Adapter/Fille.pm',
    ABSTRACT_FROM    => 'lib/Log/Any/Adapter/Fille.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Log::Any'  => 0,
        'utf8::all' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            license     => [ 'http://dev.perl.org/licenses/' ],
            bugtracker  => {
                web    => 'https://github.com/ivanych/Log-Any-Adapter-Fille/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/ivanych/Log-Any-Adapter-Fille.git',
                web  => 'https://github.com/ivanych/Log-Any-Adapter-Fille',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Log-Any-Adapter-Fille-*' },
);
