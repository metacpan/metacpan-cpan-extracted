use ExtUtils::MakeMaker;

use 5.008001;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text FindRef.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    PREREQ_PM    => {
       common::sense    => 0,
    },
    NAME => "Devel::FindRef",
    VERSION_FROM => "FindRef.pm",
);

