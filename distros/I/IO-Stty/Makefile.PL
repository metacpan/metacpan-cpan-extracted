
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'IO::Stty',
    AUTHOR              => 'Austin Schutz <auschutz@cpan.org>',
    VERSION_FROM        => 'lib/IO/Stty.pm',
    ABSTRACT_FROM       => 'lib/IO/Stty.pm',
    PL_FILES            => {},
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'        => 'perl', ) : ()),
    PREREQ_PM => {
        'Test::More' => 0,  # For testing
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IO-Stty-*' },
    META_MERGE  => {
        build_requires => {
            'Test::More' => 0,  # For testing
            'ExtUtils::MakeMaker' => 0,
        },
        resources => {
            license => 'http://dev.perl.org/licenses/',
            homepage => 'http://wiki.github.com/toddr/IO-Stty',
            bugtracker => 'http://github.com/toddr/IO-Stty/issues',
            repository => 'http://github.com/toddr/IO-Stty',
        },
    },
);
