use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'JavaScript::Duktape',
    VERSION_FROM   => 'lib/JavaScript/Duktape.pm',
    ABSTRACT_FROM  => 'lib/JavaScript/Duktape.pm',
    LICENSE        => 'perl',
    AUTHOR         => 'Mamod Mehyar <mamod.mehyar@gmail.com>',
    META_MERGE => {
        resources => {
            repository => 'git://github.com/mamod/JavaScript-Duktape.git',
            bugtracker => 'https://github.com/mamod/JavaScript-Duktape/issues',
        },
    },
    test              => {TESTS => join( ' ', (glob( 't/*.t'), glob('t/*/*.t'), , glob('t/*/*/*.t')))},
    CONFIGURE_REQUIRES => {
        'Inline::MakeMaker'   => '0.51',
        'ExtUtils::MakeMaker' => '6.63',
    },
    PREREQ_PM         => {
        'Inline'      => '0.80',
        'Inline::C'   => '0.75',
    },
    TEST_REQUIRES     => {
        'Test::Fatal'   => '0.014',
        'Try::Tiny'     => '0.24',
    }
);
