use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Log::Log4perl::Layout::XMLLayout',
    'VERSION_FROM'	=> 'lib/Log/Log4perl/Layout/XMLLayout.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Log::Log4perl' => 0.1}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Log/Log4perl/Layout/XMLLayout.pm', # retrieve abstract from module
       AUTHOR     => 'G. Carls <gcarls@cpan.org>') : ()),
);
