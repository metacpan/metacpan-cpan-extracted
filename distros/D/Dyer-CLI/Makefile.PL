use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'Dyer::CLI',
	VERSION_FROM => 'lib/Dyer/CLI.pm',
	PREREQ_PM => {
		'Getopt::Std' => 0,
		'Carp' => 0,
	},
	EXE_FILES => ['bin/mkperlbin', 'bin/renamerfpi'],
);
