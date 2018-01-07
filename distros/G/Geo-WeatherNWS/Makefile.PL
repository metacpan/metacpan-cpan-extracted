use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Geo::WeatherNWS',
    AUTHOR              => q{Marc Slagle <marc.slagle@online-rewards.com>},
    VERSION_FROM        => 'lib/Geo/WeatherNWS.pm',
    ABSTRACT_FROM       => 'lib/Geo/WeatherNWS.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Net::FTP' => 2.50,
        'LWP::UserAgent' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Geo-WeatherNWS-*' },
);
