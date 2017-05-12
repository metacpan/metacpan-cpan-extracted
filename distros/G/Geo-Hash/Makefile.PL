use 5.006001;

use strict;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'Geo::Hash',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Geo/Hash.pm',
    ABSTRACT_FROM => 'lib/Geo/Hash.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Geo-Hash-*' },
);
