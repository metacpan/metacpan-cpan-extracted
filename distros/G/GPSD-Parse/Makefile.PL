use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'GPSD::Parse',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/GPSD/Parse.pm',
    ABSTRACT_FROM    => 'lib/GPSD/Parse.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/gpsd-parse/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/gpsd-parse.git',
                web => 'https://github.com/stevieb9/gpsd-parse',
            },
        },
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'GPSD-Parse-*' },
);
