use ExtUtils::MakeMaker;

use Canary::Stability Geo::LatLon2Place => 1, 5.008;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text LatLon2Place.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Geo::LatLon2Place",
    LIBS => ["-lcdb"],
    VERSION_FROM => "LatLon2Place.pm",
    CONFIGURE_REQUIRES => {
       "ExtUtils::MakeMaker" => 6.6,
       "Canary::Stability" => 0,
    },
    PREREQ_PM => {
       common::sense => 3.75,
    },
    EXE_FILES => ["bin/geo-latlon2place-makedb"],
);

