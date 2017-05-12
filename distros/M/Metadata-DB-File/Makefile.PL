use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => 'Metadata::DB::File',
   VERSION_FROM => 'lib/Metadata/DB/File.pm',
   PREREQ_PM => {      
      'Metadata::DB' => 0,
      'LEOCHARRE::Database' => '1.12',
      'LEOCHARRE::DEBUG' => 0,
      'LEOCHARRE::Class' => 0,
   },
#   EXE_FILES => ['bin/mdf'],
   
);
