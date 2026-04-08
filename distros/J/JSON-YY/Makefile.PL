use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    NAME          => 'JSON::YY',
    VERSION_FROM  => 'lib/JSON/YY.pm',
    ABSTRACT_FROM => 'lib/JSON/YY.pm',
    AUTHOR        => 'vividsnow',
    LICENSE       => 'perl_5',
    MIN_PERL_VERSION => '5.014',
    OBJECT        => 'YY$(OBJ_EXT) yyjson$(OBJ_EXT)',
    INC           => '-I.',
    CCFLAGS       => "$Config{ccflags} -std=c99",
    OPTIMIZE      => '-O3',
    PREREQ_PM     => {},
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/JSON-YY.git',
                web  => 'https://github.com/vividsnow/JSON-YY',
            },
        },
    },
);
