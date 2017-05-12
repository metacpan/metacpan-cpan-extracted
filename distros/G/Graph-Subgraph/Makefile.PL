use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Graph::Subgraph',
    AUTHOR              => q{Konstantin S. Uvarin <khedin@gmail.com>},
    VERSION_FROM        => 'lib/Graph/Subgraph.pm',
    ABSTRACT_FROM       => 'lib/Graph/Subgraph.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Graph' => 0,
		'Carp' => 0,
		'Test::Exception' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Graph-Subgraph-*' },
);
