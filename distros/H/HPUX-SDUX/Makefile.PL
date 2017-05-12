use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HPUX::SDUX',
    'VERSION_FROM'	=> 'SDUX.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'SDUX.pm', # retrieve abstract from module
       AUTHOR     => 'Hiro Asari <hiro@asari.net>') : ()),
#    'INSTALLDIRS'		=> 'site',
#	 'PREFIX'		=> 'sdux',
);
