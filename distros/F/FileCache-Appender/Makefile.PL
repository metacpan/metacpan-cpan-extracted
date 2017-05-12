use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    NAME          => 'FileCache::Appender',
    AUTHOR        => q{Pavel Shaydo <zwon@cpan.org>},
    VERSION_FROM  => 'lib/FileCache/Appender.pm',
    ABSTRACT_FROM => 'lib/FileCache/Appender.pm',
    LICENSE       => 'perl',
    PL_FILES      => {},
    PREREQ_PM     => { 'Path::Tiny' => 0.012, },
    TEST_REQUIRES => {
        'Test::Most'         => 0.22,
        'Test::FailWarnings' => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.64,
    },
    dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => 'FileCache-Appender-*' },
    META_MERGE => {
        no_index => {
            file => 'README.pod'
        },
        resources => {

            homepage   => 'https://github.com/trinitum/perl-FileCache-Appender',
            bugtracker => 'https://github.com/trinitum/perl-FileCache-Appender/issues',
            repository => 'git://github.com/trinitum/perl-FileCache-Appender',

            license => 'http://dev.perl.org/licenses/',
        },
    },
);
