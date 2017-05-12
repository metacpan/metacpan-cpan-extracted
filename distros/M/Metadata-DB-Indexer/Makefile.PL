use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => 'Metadata::DB::Indexer',
   VERSION_FROM  => 'lib/Metadata/DB/Indexer.pm',
   PREREQ_PM => {
      'File::Find::Rule' => '0.30',
      'Metadata::DB' => '1.11',
      'Test::Simple' => '0.7',
      'LEOCHARRE::DEBUG' => '1.11',
      'LEOCHARRE::Class2' => '1.03',
      'Metadata::DB::Analizer' => '1.02',
      'File::Path' => '1.08',
      'Smart::Comments' => '0',
      'Cwd' => '3',
      'DBI' => '1.50',
   },
);
