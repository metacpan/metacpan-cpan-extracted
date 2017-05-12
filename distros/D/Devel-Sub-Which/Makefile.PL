require 5.006;

use ExtUtils::MakeMaker;

WriteMakefile (
	'NAME' => 'Devel::Sub::Which',
	'VERSION_FROM' => 'lib/Devel/Sub/Which.pm',
	'PREREQ_PM' => {
		'Test::use::ok' => 0,
		'Test::Exception' => 0,
		'Test::More' => 0,
		'Sub::Identify' => 0,
		'Sub::Exporter' => 0,
	},
	'INSTALLDIRS' => 'site',
	'EXE_FILES' => [],
	'PL_FILES' => {},
	'SIGN' => 1,
);
