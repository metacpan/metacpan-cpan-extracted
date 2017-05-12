use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = (
    NAME                => 'IBGE::Municipios',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/IBGE/Municipios.pm',
    ABSTRACT_FROM       => 'lib/IBGE/Municipios.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0.88,
    },
    META_MERGE      => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/garu/IBGE-Municipios/issues',
            repository  => 'http://github.com/garu/IBGE-Municipios',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'IBGE-Municipios-*' },
);


WriteMakefile( %options );

