use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'GD::Text::Arc',
    'VERSION_FROM'	=> 'Arc.pm', # finds $VERSION
    'PREREQ_PM'		=> { GD => 1.2, GD::Text }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Arc.pm', # retrieve abstract from module
       AUTHOR     => 'Daniel Allen <da@coder.com>') : ()),
);
