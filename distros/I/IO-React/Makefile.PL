use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'         => 'IO::React',
	      'VERSION_FROM' => 'React.pm',
	      'PREREQ_PM'    => { 'Carp'     => 0,
				  'IO::File' => 0,
				},
	      );
