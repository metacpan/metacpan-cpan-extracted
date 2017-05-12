use 5.008001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Log::Any::Adapter::Dupstd',
    AUTHOR           => [ 'Mikhail Ivanov <m.ivanych@gmail.com>', 'Anastasia Zherebtsova <zherebtsova@gmail.com>' ],
    VERSION_FROM     => 'lib/Log/Any/Adapter/Dupstd.pm',
    ABSTRACT_FROM    => 'lib/Log/Any/Adapter/Dupstd.pm',
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
                web    => 'https://github.com/ivanych/Log-Any-Adapter-Dupstd/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/ivanych/Log-Any-Adapter-Dupstd.git',
                web  => 'https://github.com/ivanych/Log-Any-Adapter-Dupstd',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Log-Any-Adapter-Dupstd-*' },
);
