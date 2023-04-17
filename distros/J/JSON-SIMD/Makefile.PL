use 5.008003;
use ExtUtils::MakeMaker;

#use Canary::Stability JSON::SIMD => 1, 5.008003;

WriteMakefile(
    dist	 => {
	             PREOP	=> 'pod2text SIMD.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	             COMPRESS	=> 'gzip -9v',
	             SUFFIX	=> '.gz',
	            },
    EXE_FILES    => [ "bin/json_simd" ],
    VERSION_FROM => "SIMD.pm",
    NAME         => "JSON::SIMD",
    PREREQ_PM    => {
       common::sense     => 0,
       Types::Serialiser => 0,
    },
    CONFIGURE_REQUIRES => { ExtUtils::MakeMaker => 6.52 },
    OBJECT => '$(O_FILES)',
    LD => 'g++',
    OPTIMIZE => '-O3',
    CCFLAGS => "$Config::Config{ccflags} -DSIMDJSON_EXCEPTIONS=0 -DNDEBUG",
);

