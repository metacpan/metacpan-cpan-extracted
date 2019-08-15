use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Geoffrey::Changelog::Database',
    AUTHOR        => 'Mario Zieschang <mziescha@cpan.org>',
    VERSION_FROM  => 'lib/Geoffrey/Changelog/Database.pm',
    ABSTRACT_FROM => 'lib/Geoffrey/Changelog/Database.pm',
    MIN_PERL_VERSION   => 5.24.0,
    PL_FILES      => {},
    PREREQ_PM     => {
        'Geoffrey'      => 0.000103,
        'SQL::Abstract' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/GeoffreyDB/Geoffrey-Changelog-Database.git',
                web  => 'https://gitlab.com/GeoffreyDB/Geoffrey-Changelog-Database',
            },
        }
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Geoffrey-Changelog-Database-*' },
);
