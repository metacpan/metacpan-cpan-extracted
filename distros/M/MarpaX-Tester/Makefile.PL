use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'MarpaX::Tester',
    AUTHOR           => q{Michael Roberts <michael@vivtek.com>},
    VERSION_FROM     => 'lib/MarpaX/Tester.pm',
    ABSTRACT_FROM    => 'lib/MarpaX/Tester.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    EXE_FILES           => [ qw(script/marpa-test) ],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Marpa::R2' => 0,
        'Getopt::Euclid' => 0,
        'File::Slurp' => 0,
        'Inline::Files' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
               type => 'git',
               url  => 'https://github.com/Vivtek/MarpaX-Tester.git',
               web  => 'https://github.com/Vivtek/MarpaX-Tester',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MarpaX-Tester-*' },
);
