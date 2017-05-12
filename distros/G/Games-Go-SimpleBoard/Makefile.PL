require 5.008;

use ExtUtils::MakeMaker;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text SimpleBoard.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    DIR		=> [],
    NAME	=> 'Games::Go::SimpleBoard',
    VERSION_FROM => 'SimpleBoard.pm',
    EXTRA_META  => q{
recommends:
  Audio::Play: 1
    },
);



