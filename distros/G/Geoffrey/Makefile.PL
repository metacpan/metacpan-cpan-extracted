use 5.10.0;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Geoffrey',
    AUTHOR             => q{Mario Zieschang <mziescha@cpan.org>},
    VERSION_FROM       => 'lib/Geoffrey.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.10.0,
    EXE_FILES          => [],
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    PREREQ_PM          => {
        'DBI',              => 1.632,
        'DBD::SQLite',      => 1.4,
        'Exception::Class', => 0,
        'File::Slurp',      => 9999.19,
        'File::Spec',       => 0,
        'Hash::MD5',        => 0.08,
        'Perl::Version',    => 0,
        'Ref::Util',        => 0,
        'Readonly',         => 0,
        'SQL::Abstract',    => 0,
        'Test::Builder',    => 0,
        'Time::Piece',      => 1.27,
        'Test::Exception',  => 0,
    },
    TEST_REQUIRES => {},
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/GeoffreyDB/Geoffrey.git',
                web  => 'https://gitlab.com/GeoffreyDB/Geoffrey',
            },
        }
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Geoffrey-*' },
);
