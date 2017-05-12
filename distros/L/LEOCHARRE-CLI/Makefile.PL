if( $^O=~/mswin32/i ) { print("OS unsupported") and exit; }
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'LEOCHARRE::CLI',
	VERSION_FROM => 'lib/LEOCHARRE/CLI.pm',
	PREREQ_PM => {
		'Getopt::Std' => 0,
      'LEOCHARRE::DEBUG' => 0,
		'Carp' => 0,
		'YAML' => 0,
      'File::Which' => 0,
      'File::chmod' => 0,
      'Linux::usermod' => 0,

	},
	#EXE_FILES => ['bin/mkperlbin', 'bin/renamerfpi'],
);
