use ExtUtils::MakeMaker;
WriteMakefile( NAME => "Getopt-Function",
	       VERSION_FROM => "lib/Getopt/Function.pm",
	       dist => {COMPRESS => "gzip",
			SUFFIX => "gz" },
	       PREREQ_PM => { 'Getopt::Mixed' => 1.006 },
	     );
