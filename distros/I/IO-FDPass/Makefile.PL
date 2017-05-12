use ExtUtils::MakeMaker;

use Canary::Stability IO::FDPass => 1, 5.005;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text FDPass.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "IO::FDPass",
    VERSION_FROM => "FDPass.pm",
    CONFIGURE_REQUIRES => {
       "ExtUtils::MakeMaker" => 6.52,
       "Canary::Stability"   => 0,
    },
);

