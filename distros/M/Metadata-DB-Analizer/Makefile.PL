use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => 'Metadata::DB::Analizer',
   VERSION_FROM  => 'lib/Metadata/DB/Analizer.pm',
   PREREQ_PM => {
      'Metadata::DB' => '1.11',
      'LEOCHARRE::Class' => 0,
      'LEOCHARRE::DEBUG' => 0,
      'Smart::Comments' => '0',
      'Cwd' => 0,
      'DBI' => '1.57',
      'Test::Simple' => 0,
      'DBD::SQLite' => '1.10',
   },
);
