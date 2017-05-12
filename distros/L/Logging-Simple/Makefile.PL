use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Logging::Simple',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/Logging/Simple.pm',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/logging-simple/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/logging-simple.git',
                web => 'https://github.com/stevieb9/logging-simple',
            },
        },
    },
    ABSTRACT_FROM    => 'lib/Logging/Simple.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
    },
    BUILD_REQUIRES => {
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Logging-Simple-*' },
);
