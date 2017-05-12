use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'Lingua::RU::Numeric::Declension',
	'VERSION_FROM' => 'lib/Lingua/RU/Numeric/Declension.pm',
	($] >= 5.005 ?
		(
			ABSTRACT_FROM => 'lib/Lingua/RU/Numeric/Declension.pm',
			AUTHOR => 'Andrew Shitov <andy@shitov.ru>'
		)
		:
		()
	)
);
