use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'GraphViz::Graph',
    AUTHOR           => q{René Nyffenegger <rene.nyffenegger@adp-gmbh.ch>},
    VERSION_FROM     => 'lib/GraphViz/Graph.pm',
    ABSTRACT_FROM    => 'lib/GraphViz/Graph.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::Exception'   => 0,
        'Test::More'        => 0,
        'Test::Simple'      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'GraphViz-Graph-*' },
);
