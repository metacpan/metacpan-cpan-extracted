use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'GIS::Distance::Lite',
	VERSION_FROM => 'Lite.pm',
	ABSTRACT_FROM => 'Lite.pm',
	PREREQ_PM => {
			'Math::Trig' => 1.03,
		},
	AUTHOR => 'Johan Beronius <johanb@athega.se>',
);
