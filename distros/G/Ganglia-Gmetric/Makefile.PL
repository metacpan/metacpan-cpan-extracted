use ExtUtils::MakeMaker;

WriteMakefile(
   NAME                =>  'Ganglia::Gmetric',
   VERSION_FROM        =>  'lib/Ganglia/Gmetric.pm',
   AUTHOR     => 'Erik Vrolijk fungus@cpan.org',
	ABSTRACT      => "Ganglia gmetric wrapper",
   PREREQ_PM     => {
      'Class::Accessor' => '0.31',
      'IO::CaptureOutput' => '1.0801',
   },
);
