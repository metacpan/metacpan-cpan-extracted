use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'File::Cache::Persistent',
	'VERSION_FROM' => 'lib/File/Cache/Persistent.pm',
	($] >= 5.005 ?
		(
			ABSTRACT_FROM => 'lib/File/Cache/Persistent.pm',
			AUTHOR => 'Andrew Shitov <andy@shitov.ru>'
		)
		:
		()
	)
);
