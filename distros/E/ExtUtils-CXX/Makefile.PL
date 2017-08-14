use ExtUtils::MakeMaker;

use Canary::Stability ExtUtils::CXX => 1, 5.005;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text CXX.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "ExtUtils::CXX",
    VERSION_FROM => "CXX.pm",
    CONFIGURE_REQUIRES => {
       ExtUtils::MakeMaker => 7.3,
       Canary::Stability => 0,
    },
    PREREQ_PM => {
       common::sense => 3.74,
    },
);

