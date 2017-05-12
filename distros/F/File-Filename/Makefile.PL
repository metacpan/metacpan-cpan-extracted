use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'File::Filename',
	VERSION_FROM => 'lib/File/Filename.pm',
   ABSTRACT_FROM => 'lib/File/Filename.pm',
   AUTHOR => 'Leo Charre leocharre at cpan dot org',
   LICENSE => 'perl',

	PREREQ_PM => {
		'Exporter' => 5,
		'Carp' => 0,
      'Test::Simple' => 0,
	},
);
