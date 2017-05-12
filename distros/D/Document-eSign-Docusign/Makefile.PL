use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME   => 'Document::eSign::Docusign',
    AUTHOR => q{Tyler Hardison <tyler@seraph-net.net>, 
                Gavin Henry <ghenry@surevoip.co.uk>},
    VERSION_FROM       => 'lib/Document/eSign/Docusign.pm',
    ABSTRACT_FROM      => 'lib/Document/eSign/Docusign.pm',
    LICENSE            => 'Artistic_2_0',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES     => { 'Test::More' => 0, },
    PREREQ_PM          => {
        JSON             => 0,
        'LWP::UserAgent' => 6.22,
        'HTTP::Headers'  => 0,
        'XML::LibXML'    => 0,
        'URI'            => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Document-eSign-Docusign-*' },
);
