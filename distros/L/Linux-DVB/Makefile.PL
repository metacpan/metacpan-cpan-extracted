use ExtUtils::MakeMaker;

use Canary::Stability Linux::DVB => 1, 5.006;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text DVB.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    CONFIGURE_REQUIRES => { ExtUtils::MakeMaker => 6.52, Canary::Stability => 2001 },
    NAME => "Linux::DVB",
    VERSION_FROM => "DVB.pm",
);

