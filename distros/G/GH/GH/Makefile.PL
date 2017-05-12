use ExtUtils::MakeMaker;
WriteMakefile(NAME => "GH",
	VERSION => "0.55",
	CCFLAGS => "-g",
	OPTIMIZE=>"-g -O0",
	DIR => ['Status', 'EditOp', 'Msp', 'MspTools', 'Align', 'Sim4']);
