use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'IO::CSVHeaderFile',
    'VERSION_FROM'	=> 'CSVHeaderFile.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Text::CSV_XS' => 0.20}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'CSVHeaderFile.pm', # retrieve abstract from module
       AUTHOR     => 'Vasek Balcar <vasek@ti.cz>') : ()),
);
