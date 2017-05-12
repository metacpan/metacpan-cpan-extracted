use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Interchange::Search::Solr',
    AUTHOR           => q{Marco Pessotto <melmothx@gmail.com>},
    VERSION_FROM     => 'lib/Interchange/Search/Solr.pm',
    ABSTRACT_FROM    => 'lib/Interchange/Search/Solr.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    EXE_FILES        => ['bin/solr_update'],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'YAML' => 0,
        'DateTime' => 0,
    },
    PREREQ_PM => {
                  'WebService::Solr' => 0,
                  'Lingua::StopWords' => 0.09, # also on debian
                  'Type::Tiny' => 1,
                  'namespace::clean' => 0,
                  'Moo' => 0,
                  'XML::LibXML' => 0,
                 },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Interchange-Search-Solr-*' },
	    META_MERGE        => {
        resources => {
            repository  => 'https://github.com/interchange/Interchange-Search-Solr.git',
            bugtracker => 'https://github.com/interchange/Interchange-Search-Solr/issues',
            IRC => 'irc://irc.freenode.net/#interchange',
        },
    },
);
