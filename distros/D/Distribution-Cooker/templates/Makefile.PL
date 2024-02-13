use ExtUtils::MakeMaker 6.46;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	        => '« $module »',
	'ABSTRACT_FROM' => 'lib/« $module_path »',
	'VERSION_FROM'  => 'lib/« $module_path »',
	'LICENSE'       => 'perl',
	'AUTHOR'        => '« $author_name » <« $email »>',

	'PREREQ_PM'    => {
		'Test::More' => '0.95',
		},

	clean  => { FILES    => q|« $module_dist »-*| },
	);
