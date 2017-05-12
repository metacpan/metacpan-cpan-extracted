use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => 'Metadata::DB::Search',
   VERSION_FROM  => 'lib/Metadata/DB/Search.pm',
   PREREQ_PM => {
      'Metadata::DB' => '1.11',
      'Test::Simple' => '0.7',
      'LEOCHARRE::Class2' => '1.03',
      'LEOCHARRE::DEBUG' => '1.11',
      'Cwd' => '3',
      'DBI' => '1.57',
      'Smart::Comments' => 0,
   },
);
