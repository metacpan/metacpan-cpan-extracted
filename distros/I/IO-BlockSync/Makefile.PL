use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'IO::BlockSync',
    AUTHOR =>
      q{Thor Dreier-Hansen <43479811+thordreier@users.noreply.github.com>},
    VERSION_FROM       => 'lib/IO/BlockSync.pm',
    ABSTRACT_FROM      => 'lib/IO/BlockSync.pm',
    LICENSE            => 'perl_5',
    EXE_FILES          => ['bin/blocksync'],
    MIN_PERL_VERSION   => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'namespace::clean'      => '0.27',
        'Log::Log4perl'         => '1.48',
        'Moo'                   => '2.002',
        'MooseX::Log::Log4perl' => '0.47',
        'MooX::Options'         => '4.023',
        'Try::Tiny'             => '0.28',
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources   => {
            homepage   => 'https://github.com/thordreier/',
            repository => {
                type => 'git',
                url  => 'git://github.com/thordreier/perl-IO-BlockSync.git',
                web  => 'https://github.com/thordreier/perl-IO-BlockSync',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'IO-BlockSync-*' },
);
