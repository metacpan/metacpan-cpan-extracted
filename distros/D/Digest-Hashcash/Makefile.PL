use ExtUtils::MakeMaker;

use Canary::Stability Digest::Hashcash => 1, 5.005;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Hashcash.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Digest::Hashcash",
    VERSION_FROM => "Hashcash.pm",
    PREREQ_PM   => {
       Time::HiRes => 1.2,
       Time::Local => 0,
    },
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 6.52, "Canary::Stability" => 0 },
);

