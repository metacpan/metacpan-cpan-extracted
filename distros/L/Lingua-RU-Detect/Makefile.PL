use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'Lingua::RU::Detect',
	'VERSION_FROM' => 'lib/Lingua/RU/Detect.pm',
	($] >= 5.005 ?
		(
			ABSTRACT_FROM => 'lib/Lingua/RU/Detect.pm',
			AUTHOR => 'Andrew Shitov <andy@shitov.ru>'
		)
		:
		()
	)
);
