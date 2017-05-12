use Inline::MakeMaker;
WriteInlineMakefile(
    NAME              => 'Freq',
    VERSION_FROM      => 'Freq.pm', # finds $VERSION
    PREREQ_PM         => { FileHandle => 0.01, # actually later
                           CDB_File => 0.01,   # actually later
						   Inline => 0.43 }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Freq.pm', # retrieve abstract from module
       AUTHOR         => 'Ira Woodhead <ira at sweetpota dot to>') : ()),
);
