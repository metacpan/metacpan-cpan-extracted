use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Geo::Code::XYZEN',
    AUTHOR           => q{Ervin Ruci <eruci@geocode.xyz>},
    VERSION_FROM     => 'lib/Geo/Code/XYZEN.pm',
    ABSTRACT_FROM    => 'lib/Geo/Code/XYZEN.pm',
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
        'Math::BigInt' => 1
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Geo-Code-XYZEN*' },
);

