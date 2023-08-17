use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = (
    NAME                => 'ENV::Util',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/ENV/Util.pm',
    ABSTRACT_FROM       => 'lib/ENV/Util.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/garu/ENV-Util/issues/',
            repository  => 'https://github.com/garu/ENV-Util',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'ENV-Util-*' },
);

WriteMakefile( %options );
