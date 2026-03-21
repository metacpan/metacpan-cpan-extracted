use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'File::Access::Driver',
    LICENSE          => 'perl',
    AUTHOR           => 'Bodo (Hugo) Barwich <b.barwich@hotmail.com>',
    VERSION_FROM     => 'lib/File/Access/Driver.pm',
    MIN_PERL_VERSION => '5.010',
    test             => { TESTS => 't/*.t' },
    BUILD_REQUIRES   => {
        'ExtUtils::MakeMaker' => '6.46',
        'Test::More'          => '0',
    },
    PREREQ_PM => {
        'Data::Dump'  => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/bodo-hugo-barwich/file-access-driver.git',
                web  => 'https://github.com/bodo-hugo-barwich/file-access-driver',
            },
            bugtracker => {
                web => 'https://github.com/bodo-hugo-barwich/file-access-driver/issues'
            },
        },
    },
);

