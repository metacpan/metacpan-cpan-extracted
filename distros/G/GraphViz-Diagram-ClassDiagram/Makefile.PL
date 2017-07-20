use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'GraphViz::Diagram::ClassDiagram',
    AUTHOR           => q{René Nyffenegger <rene.nyffenegger@adp-gmbh.ch>},
    VERSION_FROM     => 'lib/GraphViz/Diagram/ClassDiagram.pm',
    ABSTRACT_FROM    => 'lib/GraphViz/Diagram/ClassDiagram.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'GraphViz::Graph' => 0.03,
    },
    BUILD_REQUIRES => {
        'Test::Simple' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'GraphViz-ClassDiagram-*' },
);
