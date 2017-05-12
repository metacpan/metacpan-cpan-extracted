use 5.008003;
use ExtUtils::MakeMaker;

use Canary::Stability JSON::XS => 1, 5.008003;

WriteMakefile(
    dist	 => {
	             PREOP	=> 'pod2text XS.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	             COMPRESS	=> 'gzip -9v',
	             SUFFIX	=> '.gz',
	            },
    EXE_FILES    => [ "bin/json_xs" ],
    VERSION_FROM => "XS.pm",
    NAME         => "JSON::XS",
    PREREQ_PM    => {
       common::sense     => 0,
       Types::Serialiser => 0,
    },
    CONFIGURE_REQUIRES => { ExtUtils::MakeMaker => 6.52, Canary::Stability => 0 },
);

