use ExtUtils::MakeMaker;

use Canary::Stability Geo::LatLon2Place => 1, 5.010;

my $embed_cdb = $^O eq "MSWin32";

if (exists $ENV{GEO_LATLON2PLACE_EMBED_CDB}) {
   $embed_cdb = $ENV{GEO_LATLON2PLACE_EMBED_CDB};
} else {
   print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

Use embedded CDB?

On most platforms, this module will rely on the system tinycdb library
(on GNU/Debian you can "apt install libcdb-dev" for example). However,
this module can also use an embedded version of this library.

EOF

   $embed_cdb = prompt ("Use embedded tinycdb library (y/n)?", $embed_cdb ? "y" : "n") =~ /y/i;
}

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text LatLon2Place.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Geo::LatLon2Place",
    ($embed_cdb ? (DEFINE => "-DEMBED_CDB") : (LIBS => ["-lcdb"])),
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

