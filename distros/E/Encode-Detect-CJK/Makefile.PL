require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'Encode::Detect::CJK',
	'VERSION_FROM'	=>	'lib/Encode/Detect/CJK.pm',
	'PREREQ_PM'     => {
		'Encode'=>'0',
 	},
	dist		=>	{ COMPRESS => 'gzip -9f', SUFFIX => '.gz'}
);

