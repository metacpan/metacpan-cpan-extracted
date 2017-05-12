use ExtUtils::MakeMaker;

use Canary::Stability Digest::FNV::XS => 1, 5.008;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text XS.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Digest::FNV::XS",
    VERSION_FROM => "XS.pm",
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 6.52, "Canary::Stability" => 0 },
);

