use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => 'Metadata::DB',
   VERSION_FROM  => 'lib/Metadata/DB.pm',
   PREREQ_PM => {
      'Metadata::Base' => 0,
      'DBD::SQLite' => '0',
      'DBD::mysql' => 0,
      'LEOCHARRE::Class2' => '1.03',
      'LEOCHARRE::Database' => '1',
      'LEOCHARRE::DEBUG' => 0,
      'HTML::Entities' => 0,
      'HTML::Template::Default' => '1.04',
      'File::Copy' => '2',
      'Smart::Comments' => '0',
      'Cwd' => 0,



   },
);
