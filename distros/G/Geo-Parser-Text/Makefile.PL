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
  	'XML::Simple' => '2.24',
  	'LWP::UserAgent' => '6.32',
  	'HTTP::Request' => '6.14',
  	'URI' => '1.73',
  	'Data::Dumper' => '2.161',
	'utf8::all' => '0.024'
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Geo-Parser-Text-*' },
);
