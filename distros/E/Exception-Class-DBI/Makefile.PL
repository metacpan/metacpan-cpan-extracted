use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    NAME                => 'Exception::Class::DBI',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/Exception/Class/DBI.pm',
    ABSTRACT_FROM       => 'lib/Exception/Class/DBI.pm',
    MIN_PERL_VERSION    => '5.006000',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },

    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },

    TEST_REQUIRES => {
        'Test::More'    => '0.17',
        'Test::Harness' => '2.03',
    },

    PREREQ_PM => {
        'DBI'              => '1.28',
        'Exception::Class' => '1.02',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web  => 'https://github.com/plicease/Exception-Class-DBI/issues',
            },
            homepage => 'https://metacpan.org/pod/Exception-Class-DBI',
            repository => {
                type => 'git',
                url  => 'https://github.com/plicease/Exception-Class-DBI.git',
                web  => 'https://github.com/plicease/Exception-Class-DBI',
            },
        }
    },
);
