use 5.020;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'EventStore::Tiny',
    VERSION_FROM        => 'lib/EventStore/Tiny.pm',
    ABSTRACT            => 'A minimal event sourcing framework.',
    AUTHOR              => 'Mirko Westermeier <mirko@westermeier.de>',
    LICENSE             => 'mit',
    META_MERGE          => {
        resources   => {
            bugtracker  => 'http://github.com/memowe/EventStore-Tiny/issues',
            repository  => 'http://github.com/memowe/EventStore-Tiny',
        },
    },
    MIN_PERL_VERSION    => '5.20.0',
    PREREQ_PM           => {
        'Class::Tiny'   => '1.006',
        'Clone'         => '0.39',
        'Data::Compare' => '1.25',
        'Data::Dump'    => '1.23',
        'UUID::Tiny'    => '1.04',
        'YAML::Syck'    => '1.31',
    },
    TEST_REQUIRES       => {
        'Test::Pod'             => '1.52',
        'Test::Pod::Coverage'   => '1.10',
    },
    test                => {TESTS => 't/*.t t/*/*.t'}
);
