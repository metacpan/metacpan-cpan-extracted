use 5.006001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Minio',
    AUTHOR           => q{<v.nikitenko@list.ru>},
    VERSION_FROM     => 'lib/Minio.pm',
    #ABSTRACT_FROM    => 'lib/Minio.pm',
    LICENSE          => 'lgpl_3_0',
    PL_FILES         => {},
    EXE_FILES => ['script/example.pl'],
    MIN_PERL_VERSION => 5.006001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
    },
    PREREQ_PM => {
			'JSON::XS' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-Distill-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vasko-de-gama/Minio.git',
                web  => 'https://github.com/vasko-de-gama/Minio',
            },
        }})
    : ()
    ),
);
