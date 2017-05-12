use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mail::Barracuda::API',
    VERSION_FROM      => 'lib/Mail/Barracuda/API.pm', # finds $VERSION
    PREREQ_PM         => {
    	'XML::Simple' => 0, 
    	'LWP::UserAgent' => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mail/Barracuda/API.pm', # retrieve abstract from module
       AUTHOR         => 'Jonathan Auer <jda@tapodi.net>') : ()),
);
