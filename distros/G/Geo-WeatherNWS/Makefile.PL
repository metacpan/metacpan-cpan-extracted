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
        'Carp'           => '0',
        'LWP::UserAgent' => '0',
        'Net::FTP'       => '2.50',
        'POSIX'          => '0',
        'Test::More'     => '0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Geo-WeatherNWS-*' },
);
