use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Geo::SweGrid',
	VERSION_FROM => 'SweGrid.pm',
	ABSTRACT_FROM => 'SweGrid.pm',
	PREREQ_PM => {
			'Math::Trig' => 1.03,
		},
	AUTHOR => 'Johan Beronius <johanb@athega.se>',
);
