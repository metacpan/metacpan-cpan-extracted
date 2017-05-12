use ExtUtils::MakeMaker;

WriteMakefile(
    dist	=> {
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Digest::Nilsimsa",
    OBJECT => q[_nilsimsa$(OBJ_EXT) Nilsimsa$(OBJ_EXT)],
    VERSION_FROM => "Nilsimsa.pm",
    'LIBS'              => [''], # e.g., '-lm'
    'DEFINE'            => '',   # e.g., '-DHAVE_SOMETHING'
    'INC'               => '',   # e.g., '-I/usr/include/other'

);

#PREOP	=> 'pod2text Nilsimsa.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
