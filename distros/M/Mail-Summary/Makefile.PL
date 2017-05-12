use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Mail::Summary',
    'VERSION_FROM'	=> 'Summary.pm', # finds $VERSION
    'PREREQ_PM'		=> { Lingua::EN::Summarize => 0.2, 
                             Mail::Box::Manager    => 2.013 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Summary.pm', # retrieve abstract from module
       AUTHOR     => 'Stray Toaster <coder@stray-toaster.co.uk>') : ()),
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
);
