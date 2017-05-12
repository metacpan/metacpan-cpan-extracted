use ExtUtils::MakeMaker;

use 5.0010;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Faster.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Faster",
    VERSION_FROM => "Faster.pm",
);

