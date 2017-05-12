use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTML::Template::Set',
    'VERSION_FROM'	=> 'Set.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        Carp           => 1.01,
        HTML::Template => 2.6
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Set.pm', # retrieve abstract from module
       AUTHOR     => 'David Radunz <dj@boxen.net>') : ()),
);
