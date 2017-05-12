use ExtUtils::MakeMaker;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Clone.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
#    PREREQ_PM => {
#       common::sense => 0,
#    },
    NAME => "Linux::Clone",
    VERSION_FROM => "Clone.pm",
);

