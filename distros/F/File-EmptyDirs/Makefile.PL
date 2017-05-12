use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'File::EmptyDirs',
   VERSION_FROM => 'lib/File/EmptyDirs.pm',
   ABSTRACT_FROM => 'lib/File/EmptyDirs.pm',   
   AUTHOR => 'Leo Charre leocharre at cpan dot org',


   # gen /usr/bin/pmused by Thu Sep 17 17:27:09 EDT 2009 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Exporter'                          => '5',
      'File::Find::Rule'                  => '0.30',
      'File::Find::Rule::DirectoryEmpty'  => '1.11',
      'File::Path'                        => '1.08',
      'LEOCHARRE::CLI2'                   => '1.07',
      'Test::Simple'                      => '0',
   },
   
   LICENSE => 'perl',
   
   EXE_FILES => [qw(bin/ermdir)],
);


