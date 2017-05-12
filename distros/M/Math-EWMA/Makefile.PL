use ExtUtils::MakeMaker;

require 5.006;

WriteMakefile(
	'NAME'	=> 'Math::EWMA',
	'VERSION_FROM' => 'lib/Math/EWMA.pm', # finds $VERSION
	'AUTHOR' => 'Samuel Smith',
	'ABSTRACT_FROM' => 'lib/Math/EWMA.pm',
	'PREREQ_PM' => { 
		'namespace::autoclean' => '0',
		'Test::Exception' => '0',
		'Test::More' => '0',
		'Moo' => '1.001000',
		'Scalar::Util' => '0', 
	},
	'LICENSE' => 'perl_5',
	'META_MERGE'        => {
		'resources' => {
			'repository'  =>  'https://github.com/smith153/Math-EWMA',
			},
		},
);

