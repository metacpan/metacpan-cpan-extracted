use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Devel::Trace::Subs',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/Devel/Trace/Subs.pm',
    ABSTRACT_FROM    => 'lib/Devel/Trace/Subs.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.008',
    CONFIGURE_REQUIRES => {
        'Cwd' => 0,
        'ExtUtils::MakeMaker' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/stevieb9/devel-trace-subs/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/devel-trace-subs.git',
                web => 'https://github.com/stevieb9/devel-trace-subs',
            },
        },
    },
    BUILD_REQUIRES => {
        'Mock::Sub' => '1.01',
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'HTML::Template' => 0,
        'Template' => 0,
        'Symbol' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Devel-Trace-Subs-*' },
);
