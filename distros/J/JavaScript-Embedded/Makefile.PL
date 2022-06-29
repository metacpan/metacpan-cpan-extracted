use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'JavaScript::Embedded',
    VERSION_FROM   => 'lib/JavaScript/Embedded.pm',
    ABSTRACT_FROM  => 'lib/JavaScript/Embedded.pm',
    LICENSE        => 'perl',
    AUTHOR         => 'Rene Schickbauer <cavac@cpan.org>',
    META_MERGE => {
        resources => {
            repository => 'https://cavac.at/public/mercurial/JavaScript-Embedded/'
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
