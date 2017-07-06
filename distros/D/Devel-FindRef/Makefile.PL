use ExtUtils::MakeMaker;

use Canary::Stability Devel::FindRef => 1, 5.008003;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text FindRef.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    PREREQ_PM    => {
       common::sense    => 0,
    },
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 6.52, "Canary::Stability" => 0 },
    TEST_REQUIRES => {
       Task::Weaken     => 0,
    },
    NAME => "Devel::FindRef",
    VERSION_FROM => "FindRef.pm",
);

