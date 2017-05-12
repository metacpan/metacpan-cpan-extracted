use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Ham::Resources::HamQTH',
    VERSION_FROM      => 'lib/Ham/Resources/HamQTH.pm', # finds $VERSION
    PREREQ_PM         => {
    		'LWP::UserAgent' => 0,
    		'XML::LibXML::Reader' => 0,
    		'Test::More' => 0,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Ham/Resources/HamQTH.pm', # retrieve abstract from module
       AUTHOR         => 'Carlos Juan <ea3hmb@gmail.com>') : ()),
);
