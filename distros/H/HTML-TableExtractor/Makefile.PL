use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTML::TableExtractor',
    'VERSION_FROM'	=> 'TableExtractor.pm', # finds $VERSION
    'PREREQ_PM'		=> {HTML::Parser => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'TableExtractor.pm', # retrieve abstract from module
       AUTHOR     => 'Simon Drabble <simon@thebigmachine.org>') : ()),
);
