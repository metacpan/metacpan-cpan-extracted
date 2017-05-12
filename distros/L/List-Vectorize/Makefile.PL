use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'List::Vectorize',
	VERSION_FROM  => 'lib/List/Vectorize.pm',
	PREREQ_PM     => {
		'Data::Dumper' => 0,
		'Test::More'   => 0,
		'Carp'         => 0,
	},
	EXE_FILES     => ["bin/l_intersect",
	                  "bin/l_sapply",
					  "bin/l_setdiff", 
					  "bin/l_sort", 
					  "bin/l_subset", 
					  "bin/l_union", 
					  "bin/l_unique"], 
	AUTHOR        => 'Zuguang Gu <jokergoo@gmail.com>',
	ABSTRACT      => 'functions to make vectorized calculation easy',
	LICENSE       => 'perl',
);
