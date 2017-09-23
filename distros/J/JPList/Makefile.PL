use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'JPList',
    AUTHOR       => q{Sheeju Alex <sheejuec7@gmail.com>},
    VERSION_FROM => 'lib/JPList.pm',
    ABSTRACT =>
'JPList module is a data source bundle that works with Perl and database handle where as jPlist (http://jplist.com) behaves as UI module only',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'      => 0,
        'Test::Exception' => 0
    },
    PREREQ_PM => {
        'URI::Escape'          => '1.72',
        'JSON'                 => '2.90',
        'namespace::autoclean' => '0.28',
        'Moose'                => '2.1604',
        'SQL::Abstract'        => '1.81'
    },
    TEST_REQUIRES => {
        'FindBin'     => 0,
        'Test::Most'  => '0.34',
        'Test::Class' => '0.50',
        'DBI'         => '1.630'
    },
    dist       => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean      => {FILES    => 'JPList-*'},
    META_MERGE => {
        'meta-spec' => {version => 2},
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/sheeju/JPList.git',
                web  => 'https://github.com/sheeju/JPList'
            }
        }
    }
);
