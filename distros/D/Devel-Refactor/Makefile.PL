use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Devel::Refactor',
    'VERSION_FROM'	=> 'Refactor.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                               'Test::More' => '.47',
                           }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Refactor.pm', # retrieve abstract from module
       AUTHOR     => 'Scott Sotka <ssotka@barracudanetworks.com>') : ()),
);
