use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FTN-Database',
    AUTHOR              => 'Robert James Clay <jame@rocasa.us>',
    VERSION_FROM        => 'lib/FTN/Database.pm',
    ABSTRACT_FROM       => 'lib/FTN/Database.pm',
    LICENSE        	=> 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'DBI'                   => 0,
        'DBD::SQLite'           => 0,
    },
    BUILD_REQUIRES => {
        'Test::Database'        => 0,
        'Test::More'            => 0,
        'Test::Pod'             => 1.22,
        'Test::Pod::Coverage'   => 1.08,
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                type => 'git',
                url  => 'git.code.sf.net/p/ftnpl/ftn-database/code',
                web  => 'http://sourceforge.net/p/ftnpl/ftn-database/code',
             },
         }})
        : ()
    ),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FTN-Database-* t/*.DB' },
);
