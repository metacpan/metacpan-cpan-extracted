use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Graph::Maker',
    AUTHOR              => 'Matt Spear <batman900+cpan@gmail.com>',
    VERSION_FROM        => 'lib/Graph/Maker.pm',
    ABSTRACT_FROM       => 'lib/Graph/Maker.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Graph' => 0.8,
	'Math::Random' => 0,
	'Class::Factory' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Graph-Maker-*' },
);
