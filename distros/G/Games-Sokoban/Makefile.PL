use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Sokoban.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Games::Sokoban",
    VERSION_FROM => "Sokoban.pm",
    PREREQ_PM    => {
       common::sense    => 0,
    },
);

