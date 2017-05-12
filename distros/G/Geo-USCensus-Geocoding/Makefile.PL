use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Geo::USCensus::Geocoding',
    AUTHOR              => q{Mark Wells <mark@freeside.biz>},
    VERSION_FROM        => 'Geocoding.pm',
    ABSTRACT_FROM       => 'Geocoding.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'LWP::UserAgent' => 0,
        'Text::CSV'      => 0,
        'Moo'            => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Geo-USCensus-Geocoding-*' },
);
