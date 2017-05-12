# $id$
use ExtUtils::MakeMaker;
require 5.6.0;


WriteMakefile(
    'NAME'         => "GOBO",
    'DISTNAME'         => "GOBO",
    'ABSTRACT'     => 'Perl library for GO and OBO',
    'AUTHOR'       => 'Chris Mungall <cjm@fruitfly.org>',
    'VERSION_FROM' => "GOBO.pm",
    'PREREQ_PM'    => {
#        'AmiGO::Model::Graph'       => 0,
        'DateTime::Format::ISO8601' => 0,
        'Test::Deep'                 => 0,
#        'DBIx::Class'               => 0,
#        'Graph'                     => 0,
        'List::MoreUtils'           => 0,
#        'Lucene'                    => 0,
        'Moose'                     => 0.81,
#        'RDF::Redland'              => 0,
#        'Set::Object'               => 0,
    },
    'EXE_FILES'    => [
        qw(
                                    bin/go-gaf-inference.pl
                                    bin/go-slimdown.pl
                                    bin/gobo-make-lucene-index.pl
                                   )
    ],
    'dist'         => { 
        'SUFFIX'       => ".gz",
        'DIST_DEFAULT' => 'all tardist',
        'COMPRESS'     => "gzip -9f" 
    },
    clean => {
        FILES => 'GOBO-$(VERSION).tar.gz',
    },
    );

