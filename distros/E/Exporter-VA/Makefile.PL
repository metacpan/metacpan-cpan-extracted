use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Exporter::VA',
    'VERSION_FROM'	=> 'VA.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'VA.pm', # retrieve abstract from module
       AUTHOR     => 'John M. Dlugosz <john@dlugosz.com>') : ()),
);
