use ExtUtils::MakeMaker;
WriteMakefile(
	      'ABSTRACT_FROM' => 'Mediasurface.pm',
	      'AUTHOR' => 'Nigel Wetters <nwetters@cpan.org>',
	      'NAME' => 'Db::Mediasurface',
	      'PREREQ_PM' => {
		  'DBI'                          => '0',
		  'Db::Mediasurface::Cache'      => '0',
		  'Db::Mediasurface::ReadConfig' => '0'
	      },
	      'VERSION_FROM' => 'Mediasurface.pm',
);
