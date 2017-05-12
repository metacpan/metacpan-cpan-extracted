use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MP3::Find',
    VERSION_FROM      => 'lib/MP3/Find.pm',
    PREREQ_PM         => { 
        'MP3::Info'    => 0, 
        'File::Find'   => 0,
        'Scalar::Util' => 0,
    },
    EXE_FILES => [qw(
        bin/mp3find
        bin/mp3db
    )],    
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MP3/Find.pm', # retrieve abstract from module
       AUTHOR         => 'Peter Eichman <peichamn@cpan.org>') : ()),
);
