use ExtUtils::MakeMaker;
WriteMakefile(NAME => "GH",
	VERSION => "0.67",
	OPTIMIZE => "-g -O0",
	DIR => ['GH', 'utils']);
