use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'Geo::Lookup::ByTime',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    VERSION_FROM  => 'lib/Geo/Lookup/ByTime.pm',
    ABSTRACT_FROM => 'lib/Geo/Lookup/ByTime.pm',
    LICENSE       => 'perl',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Geo-Lookup-ByTime-*' },
);
