use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'GH',
	INST_LIB => "../GH/blib/lib",
	INST_ARCHLIB => "../GH/blib/arch",
	# only test overlap for now, the other tests aren't finished.
	test => {
		TESTS => 't/overlap.t'
		},
	EXE_FILES => ["overlap", "place-bac-ends", "revcomp"]
);
