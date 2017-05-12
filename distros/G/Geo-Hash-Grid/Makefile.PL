use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Geo::Hash::Grid',
    AUTHOR           => q{Adam Wohld <adam@spatialsystems.org>},
    VERSION_FROM     => 'lib/Geo/Hash/Grid.pm',
    ABSTRACT_FROM    => 'lib/Geo/Hash/Grid.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moo'           => 0,
		'Geo::Hash::XS' => 0.00015,
		'namespace::clean' => 0,
		'Scalar::Util'  => 0,
		'Carp'			=> 0,	
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Geo-Hash-Grid-*' },
);
