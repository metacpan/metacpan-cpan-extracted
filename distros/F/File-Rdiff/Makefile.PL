use ExtUtils::MakeMaker;

require 5.005;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Rdiff.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    LIBS	=> ['-lrsync'],
    NAME => "File::Rdiff",
    VERSION_FROM => "Rdiff.pm",
);

