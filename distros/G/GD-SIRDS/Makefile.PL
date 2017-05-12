use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'GD::SIRDS',
    'VERSION_FROM'	=> 'SIRDS.pm', # finds $VERSION
    'PREREQ_PM'		=> { GD => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'SIRDS.pm', # retrieve abstract from module
       AUTHOR     => 'David Hand <cogent@cpan.org>') : ()),
);
