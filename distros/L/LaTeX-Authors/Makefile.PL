use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'LaTeX::Authors',
    'VERSION_FROM'	=> 'Authors.pm', # finds $VERSION
    'PREREQ_PM'		=> {Text::Balanced => 1.80}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Authors.pm', # retrieve abstract from module
       AUTHOR     => 'Christian Rossi CCSD/CNRS <rossi@in2p3.fr> and LORIA/INRIA Lorraine <rossi@loria.fr>') : ()),
);
