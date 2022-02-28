use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Git::Lint',
    AUTHOR => 'Blaine Motsinger <blaine@renderorange.com>',
    ABSTRACT_FROM => 'lib/Git/Lint.pm',
    VERSION_FROM => 'lib/Git/Lint.pm',
    LICENSE => 'mit',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/renderorange/Git-Lint/issues',
            },
            homepage => 'https://github.com/renderorange/Git-Lint',
            repository => {
                type => 'git',
                url => 'https://github.com/renderorange/Git-Lint.git',
                web => 'https://github.com/renderorange/Git-Lint',
            },
        },
    },

    MIN_PERL_VERSION => '5.10.1',
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',  # for TEST_REQUIRES
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES => {
        'File::Spec' => 0,
        'Test::More' => '0.98',
        'Test::Deep' => 0,
        'Test::Exception' => '0.42',  # recommended by Test2
        'Test::Warnings' => 0,
    },
    PREREQ_PM => {
        'Capture::Tiny' => 0,
        'constant' => 0,
        'FindBin' => 0,
        'Getopt::Long' => '2.45',  # at least 2.45 for bugfixes
        'lib' => 0,
        'List::MoreUtils' => 0,
        'Module::Loader' => 0,
        'parent' => 0,
        'Pod::Usage' => '1.67',  # at least 1.67 for bugfixes
        'strict' => 0,
        'Try::Tiny' => 0,
        'warnings' => 0,
    },

    EXE_FILES => [
        'bin/git-lint',
    ],

    test => {
        TESTS => 't/*/*/*.t',
    },
);
