use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'File::Which::Cached',
   VERSION_FROM => 'lib/File/Which/Cached.pm',


   # gen /usr/bin/pmused by Wed Apr 22 10:20:45 EDT 2009 
   PREREQ_PM => {
      'Benchmark::Timer'                  => '0.7100',
      'Exporter'                          => '5',
      'File::Which'                       => '0.05',
      'Test::Simple'                      => '0',
   },


   EXE_FILES => [],
);


