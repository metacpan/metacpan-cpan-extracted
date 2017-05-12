use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => 'Geo::Parser::Text',
    AUTHOR           => q{Ervin Ruci <eruci@geocoder.ca>},
    VERSION_FROM     => 'lib/Geo/Parser/Text.pm',
    ABSTRACT_FROM    => 'lib/Geo/Parser/Text.pm',
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
      'XML::Simple'    => 1,
      'LWP::UserAgent' => 1,
      'URI'            => 1,
      'HTTP::Request'  => 1,	
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Geo-Parser-Text-*' },
);
