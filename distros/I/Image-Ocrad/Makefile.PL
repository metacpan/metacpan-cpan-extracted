use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

die("couldn't find ocrad binary") unless -f '/usr/bin/ocrad';

WriteMakefile(
    'NAME'		=> 'Image::Ocrad',
    'VERSION_FROM'	=> 'lib/Image/Ocrad.pm', # finds $VERSION
    'PREREQ_PM'		=> { }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Image/Ocrad.pm', # retrieve abstract from module
       AUTHOR     => 'Allen Day <allenday@ucla.edu>') : ()),
);
