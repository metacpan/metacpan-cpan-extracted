use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Disassemble::X86',
    'VERSION_FROM'	=> 'X86.pm', # finds $VERSION
    'PREREQ_PM'		=> { Test::More=>0.44 },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'X86.pm', # retrieve abstract from module
       AUTHOR     => 'Bob Mathews <bobmathews@alumni.calpoly.edu>') : ()),
);
