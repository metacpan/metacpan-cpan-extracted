use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'IO::File::Lockable',
    'VERSION_FROM'	=> 'Lockable.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Lockable.pm', # retrieve abstract from module
       AUTHOR     => 'A. U. Thor <makoto@localdomain>') : ()),
);
