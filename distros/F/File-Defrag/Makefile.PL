use ExtUtils::MakeMaker;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Defrag.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME	 => 'File::Defrag',
    VERSION_FROM => 'Defrag.pm',
    PREREQ_PM    => { Sys::FreezeThaw:: => 0.01 },
    PREREQ_FATAL => 1,
    EXE_FILES	 => [ 'bin/defrag' ],
);
