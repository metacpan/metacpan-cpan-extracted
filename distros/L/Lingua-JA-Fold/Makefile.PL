use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'         => 'Lingua::JA::Fold',
	'VERSION_FROM' => 'Fold.pm',
	'PREREQ_PM'    => {
		'Exporter' => '5.567',
		'Encode'   => '1.98',
		'Carp'     => '1.01',
	},
	($] >= 5.005 ? (
		'ABSTRACT' => 'To fold a Japanese text.',
		'AUTHOR'   => 'Masanori HATA <http://www.mihr.net/>',
	) : ()),
);
