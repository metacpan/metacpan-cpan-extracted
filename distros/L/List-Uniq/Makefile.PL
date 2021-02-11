use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'List::Uniq',
    ABSTRACT_FROM => 'lib/List/Uniq.pm',
    VERSION_FROM => 'lib/List/Uniq.pm',
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.46',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.46',
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/renderorange/List-Uniq/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/renderorange/List-Uniq.git',
                web  => 'https://github.com/renderorange/List-Uniq',
            },
        },
    },
    LICENSE => 'perl_5',
    AUTHOR => 'James FitzGibbon, <james+perl@nadt.net>',
);
